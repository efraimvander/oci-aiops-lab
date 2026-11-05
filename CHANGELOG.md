# Changelog

## [Unreleased]

### Sessão 0-1 — Fundação & Infra-estrutura como Código
- Compartment, grupo IAM e policy least-privilege (`terraform/iam.tf`)
- VCN com sub-rede pública, security list e internet gateway (`terraform/network/`)
- Instância Compute Always Free com cloud-init (Docker, Zabbix appliance, Zabbix Agent2, stress-ng) (`terraform/compute/`)
- Bucket Object Storage para o data lake do projecto (`terraform/storage/`)
- ADR-001 (Terraform) e ADR-002 (topologia de rede)
