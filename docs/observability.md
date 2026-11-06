# Observabilidade: Zabbix vs OCI Monitoring

Comparação prática entre o Zabbix (appliance em container + agent nativo)
e o OCI Monitoring nativo, ambos a monitorizar a mesma instância `aiops-vm`,
testados com carga sintética gerada por `stress-ng`.

## Como foi testado

```bash
stress-ng --cpu 2 --timeout 120s --metrics-brief
```

A carga foi observada em paralelo em:
- Zabbix web → Monitoring → Latest data → host `aiops-vm`
- OCI Monitoring → Metrics Explorer → namespace `oci_computeagent` → métrica `CpuUtilization`

## Comparação

| Critério | Zabbix | OCI Monitoring |
|---|---|---|
| Granularidade | Itens individuais muito detalhados (17 métricas de CPU sozinhas: idle, iowait, interrupt, guest, context switches, etc.) | Métricas mais agregadas (ex: `CpuUtilization` geral) |
| Custo | Grátis (self-hosted), mas consome recursos da própria instância (CPU/RAM do container) | Incluído no tier gratuito de monitorização da OCI para uso de laboratório |
| Retenção | Configurável (housekeeper interno, ajustável), mas limitada ao espaço em disco | Retenção gerida pela OCI, sem gestão manual |
| Esforço de manutenção | Alto — exige manter o próprio stack (container, agent, configuração, resolução de falhas como as documentadas no ADR-003) | Baixo — serviço gerido, sem infra-estrutura própria a manter |
| Alertas | Triggers muito configuráveis, com lógica complexa possível | Alarms mais simples, mas suficientes para a maioria dos casos |
| Integração com ferramentas existentes | Já usado no dia-a-dia profissional (Zabbix + Grafana) | Nativo da cloud, integra directamente com Notifications, Functions, etc. |

## Observações da sessão de testes

- O Zabbix mostrou-se mais rico em detalhe (17 itens de CPU só para um
  host), mas também mais frágil operacionalmente: o appliance em container
  ficou indisponível pelo menos duas vezes ao longo da sessão sem razão
  aparente nos logs, resolvido com um simples restart do container (ver
  ADR-003, ponto 9).
- O OCI Monitoring manteve-se disponível de forma consistente durante toda
  a sessão, sem qualquer intervenção manual.
- Para um ambiente de produção real, a combinação natural é usar os dois em
  conjunto: OCI Monitoring para a saúde da infra-estrutura cloud (sempre
  disponível, zero manutenção), e Zabbix para métricas de aplicação e
  lógica de negócio mais específica — é também o padrão já usado no
  dia-a-dia profissional deste projecto.

## Conclusão

Nenhuma das duas ferramentas substitui completamente a outra. A decisão de
arquitectura (ver ADR-003) é manter as duas em paralelo neste laboratório,
e mais tarde ligar os dados do Zabbix ao Object Storage/OCI Data Science
(Sessão 3-4), aproveitando a granularidade mais rica que o Zabbix oferece
para o treino do modelo de detecção de anomalias.



## Métrica personalizada

Publicada uma métrica custom via OCI CLI (namespace `aiops_lab_custom`,
métrica `lab_heartbeat`), fora do conjunto de métricas automáticas que o
`oci_computeagent` já recolhe por omissão. Serve de prova de conceito para
publicar, mais tarde, o **score de anomalia** calculado pelo modelo de
Machine Learning (Sessão 5) de volta para o OCI Monitoring.

Troubleshooting desta parte (endpoint de ingestão, formato de timestamp,
encoding do ficheiro JSON no Windows) documentado em detalhe à parte, no
ADR-004.

Comando final que funcionou:
```powershell
oci monitoring metric-data post --metric-data file://metric.json `
  --endpoint https://telemetry-ingestion.sa-saopaulo-1.oraclecloud.com
```

## Alarm e Notifications

Configurado um ciclo de alerta completo e testado de ponta a ponta:

1. **Topic** de Notifications (`aiops-lab-alerts`) com subscrição por email
2. **Alarm Definition** sobre a métrica `CpuUtilization` (namespace
   `oci_computeagent`), accionado quando a média de 1 minuto ultrapassa 50%
3. Testado com `stress-ng --cpu 2 --timeout 180s` — **email recebido com
   sucesso**, confirmando o ciclo métrica → alarm → notification em
   produção real, não só configurado

Este é o mesmo padrão que será reutilizado na Sessão 5 para alertar quando
o modelo de detecção de anomalias identificar um desvio: a infra-estrutura
de alerta já está validada e pronta a reaproveitar.