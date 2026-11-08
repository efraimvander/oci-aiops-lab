# ADR-005: Avaliação do modelo de detecção de anomalias — a armadilha do `contamination` e o trade-off precisão/recall

## Status

Aceite — implementado e validado em produção (Sessão 4, 08/11/2026).

## Contexto

Com o dataset de `CPU utilization` já limpo e rotulado (Sessão 3, `ADR-004`),
o objectivo da Sessão 4 era treinar um modelo de detecção de anomalias e
validá-lo contra os picos de carga sintética gerados com `stress-ng` e
marcados manualmente em `is_spike` (ver ADR-004).

Foi escolhido o **Isolation Forest** (`sklearn.ensemble.IsolationForest`):
um algoritmo não supervisionado que isola cada ponto através de cortes
aleatórios sucessivos — pontos anómalos, por se destacarem da maioria,
precisam de menos cortes para serem isolados, e por isso recebem uma
pontuação de anomalia mais alta.

## Problema encontrado: um resultado "perfeito demais"

A primeira tentativa de treino usou o parâmetro `contamination` (a fracção
esperada de pontos anómalos) calculado **directamente a partir do
`is_spike`**:

```python
contamination_rate = cpu["is_spike"].mean()
model = IsolationForest(contamination=contamination_rate, random_state=42)
```

Resultado: **100% de precisão e 100% de recall** — todos os 9 picos
detectados, zero falsos positivos, zero falsos negativos.

Este resultado foi correctamente identificado como **não representativo**,
por duas razões:

1. Foi usada uma única variável (`value`) cuja distribuição já separa
   claramente os picos sintéticos do resto (muito acima de 10%, enquanto a
   maioria dos pontos está abaixo de 1%) — qualquer método simples (até um
   `if valor > threshold`) teria o mesmo resultado.
2. O `contamination` foi calculado a partir do próprio `is_spike` — ou
   seja, o modelo recebeu de antemão a resposta ("há exactamente 9
   anomalias"), o que não é possível em produção, onde não existe um
   ground truth prévio.

## Decisão

Repetir o treino com um `contamination` **estimado por conhecimento de
domínio, sem usar o `is_spike`** (`0.01`, um chute razoável de ~1% de
pontos anómalos num sistema normalmente estável):

```python
model_realistic = IsolationForest(
    n_estimators=200,
    contamination=0.01,
    random_state=42
)
```

E avaliar com métricas apropriadas em vez de olhar só para a contagem de
anomalias:

```python
from sklearn.metrics import precision_score, recall_score, f1_score

precision = precision_score(cpu["is_spike"], cpu["predicted_anomaly_realistic"])
recall = recall_score(cpu["is_spike"], cpu["predicted_anomaly_realistic"])
f1 = f1_score(cpu["is_spike"], cpu["predicted_anomaly_realistic"])
```

## Resultado

| Métrica | Valor | Leitura |
|---|---|---|
| Precisão | 0.60 | Dos pontos marcados como anomalia, 60% eram picos reais (6 falsos positivos em 15 marcados) |
| Recall | 1.00 | Nenhum pico real escapou à detecção |
| F1 | 0.75 | Equilíbrio entre as duas métricas acima |

Os 6 falsos positivos correspondem a pontos moderadamente elevados — não
tão extremos como os picos do `stress-ng`, mas ainda assim fora do padrão
normal do sistema. Isto é um comportamento esperado e aceitável: em
monitorização, falhar um recall mais baixo (não detectar uma anomalia
real) é normalmente mais caro do que lidar com alguns falsos positivos.

## Consequências

- **Positivo:** o modelo e a avaliação ficam honestos — representam o que
  aconteceria num cenário real, sem ground truth disponível à partida.
- **Positivo:** o `is_spike` continua a ser útil, mas apenas como conjunto
  de validação *depois* do treino, nunca como entrada do modelo ou dos
  seus hiperparâmetros.
- **Trade-off aceite:** com `contamination=0.01`, o modelo prioriza
  recall sobre precisão (apanha tudo, com algum ruído a mais). Para um
  cenário com menos tolerância a falsos alarmes, `contamination` devia ser
  reduzido e recalibrado com mais dados históricos.
- **Lição geral:** qualquer hiperparâmetro de um modelo de anomalias que
  dependa de "quantas anomalias esperamos" é, por definição, uma estimativa
  de negócio, não um valor técnico a optimizar às cegas — vale sempre a
  pena documentar de onde veio esse número.

## Referências

- `ADR-004-resource-principal-auth.md` (dataset e rótulos usados aqui)
- Sessão 4 do programa `oci-aiops-lab`
- `processed/cpu_model_results.csv` no bucket `aiops-lab-data`
