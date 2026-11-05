# OCI AIOps Lab

![license](https://img.shields.io/badge/license-MIT-blue)

Pipeline de AIOps construído na OCI: infra-estrutura como código, observabilidade
dupla (Zabbix + OCI Monitoring), detecção de anomalias com Machine Learning, e
fecho do ciclo num dashboard Grafana. Projecto de portefólio de 9 sessões — ver
`docs/decisions/` para o raciocínio por trás de cada escolha de arquitectura.

## Pré-requisitos

- Conta OCI com crédito activo
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- Uma API key OCI (My Profile -> API Keys na consola)
- Um par de chaves SSH (`ssh-keygen -t rsa -b 4096`)

## Quick start

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edita terraform.tfvars com os teus dados (tenancy_ocid, user_ocid,
# fingerprint, private_key_path, ssh_public_key)

terraform init
terraform plan      # revê sempre antes de aplicar
terraform apply
```

No final, o Terraform mostra o IP público da instância. O Zabbix fica
acessível em `http://<ip-publico>` (login inicial `Admin` / `zabbix` —
**muda a password imediatamente**, isto é tratado como item de acção na
Sessão 6 de segurança).

Para desligar tudo e parar de consumir crédito:

```bash
terraform destroy
```

## Estrutura do repositório

```
oci-aiops-lab/
├── terraform/
│   ├── main.tf, variables.tf, outputs.tf, iam.tf, provider.tf
│   ├── network/     # VCN, sub-rede pública, security list
│   ├── compute/     # Instância + cloud-init (Docker, Zabbix, stress-ng)
│   └── storage/     # Bucket Object Storage (data lake)
├── scripts/         # Scripts auxiliares (export de métricas, inferência)
├── notebooks/        # Notebooks Jupyter do OCI Data Science
├── models/          # Model cards dos modelos treinados
├── grafana/         # Export dos dashboards
└── docs/
    └── decisions/   # Architecture Decision Records (ADRs)
```

## Sessões do programa

0. Fundação & Governança — *este Terraform já cobre a maior parte*
1. Infra-estrutura como Código — *idem*
2. Observabilidade Dupla (Zabbix + OCI Monitoring)
3. Dados: do Zabbix ao Data Lake
4. Machine Learning: Detecção de Anomalias
5. Fechar o Ciclo
6. Hardening & Segurança
7. Post-mortem & Decisões de Arquitectura
8. Publicação

## Custo real do projecto

Actualiza esta secção na Sessão 7 com o custo real consumido (ver
`docs/postmortem.md`).

## Decisões de arquitectura

Ver `docs/decisions/` — cada ADR explica uma escolha e as alternativas
consideradas.
