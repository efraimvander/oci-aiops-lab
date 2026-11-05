# ADR-001: Usar Terraform em vez de criar recursos manualmente na consola

Data: 2026-11-04
Estado: aceite

## Contexto

Os recursos deste laboratório (compartment, IAM, rede, compute, storage)
podiam ser criados directamente na consola OCI, clicando em cada serviço.

## Decisão

Toda a infra-estrutura é definida como código em Terraform, versionada no
GitHub desde o primeiro commit.

## Alternativas consideradas

- **Criar tudo na consola**: mais rápido para um único recurso, mas não é
  reproduzível nem auditável — ninguém consegue ver o histórico de alterações
  nem recriar o ambiente do zero.
- **Scripts OCI CLI avulsos**: melhor que a consola, mas sem gestão de estado
  nem plano de alterações antes de aplicar.

## Consequências

- Qualquer alteração passa a ser revista antes de aplicada (`terraform plan`).
- O ambiente inteiro pode ser destruído e recriado em minutos — útil para
  controlar custos (desligar tudo fora das sessões de trabalho).
- Custo inicial de aprendizagem de Terraform, compensado pela repetibilidade
  ao longo das 9 sessões.
