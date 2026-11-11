# ADR-006: Hardening — restringir acesso de rede e eliminar credenciais em texto simples

## Status

Aceite — implementado e validado em produção (Sessão 6, 11/11/2026).

## Contexto

Desde a Sessão 1 (ver `ADR-002-network-topology.md`), a Security List da
`aiops-public-sl` aceitava tráfego de SSH e do interface web do Zabbix a
partir de qualquer IP (`ssh_allowed_cidr = "0.0.0.0/0"`) — uma decisão
consciente para destravar o desenvolvimento inicial, mas identificada desde
então como dívida técnica a fechar antes de deixar o laboratório "estável".

Adicionalmente, duas outras dívidas acumuladas:

1. O script `scripts/export_zabbix_metrics.py` guardava a password do
   Zabbix directamente no código-fonte, em texto simples.
2. A porta 3000 (Grafana), aberta manualmente na Console OCI na Sessão 5,
   nunca tinha sido reflectida no código Terraform — uma **deriva** entre
   a infra-estrutura real e o código que a devia descrever.

## Decisão

### 1. Restringir o acesso de rede ao IP do administrador

A Security List passou a restringir SSH (22), a interface web do Zabbix
(80) e o Grafana (3000) ao IP público do administrador, em vez de
`0.0.0.0/0`:

```hcl
variable "ssh_allowed_cidr" {
  type = string
}
# terraform.tfvars
ssh_allowed_cidr = "197.148.48.61/32"
```

O tráfego ICMP (ping) manteve-se aberto a `0.0.0.0/0` — baixo risco,
útil para diagnóstico de rede.

**Limitação conhecida e aceite:** com um único IP de administrador, o
acesso é perdido sempre que esse IP mudar (ex.: troca de rede, IP
dinâmico do ISP). O suporte a múltiplos IPs (ex.: casa + escritório), via
`variable "ssh_allowed_cidr" { type = list(string) }` e um bloco
`dynamic "ingress_security_rules"`, ficou identificado como melhoria
futura, não implementada nesta sessão.

### 2. Corrigir a deriva Terraform vs Console

A regra de ingress para a porta 3000, criada manualmente na Console na
Sessão 5, foi adicionada ao código Terraform da `oci_core_security_list`.
Sem isto, um futuro `terraform apply` teria **removido silenciosamente**
essa regra, por o Terraform tratar a lista de regras de forma declarativa
(substitui o conjunto inteiro pelo que está no código, ignorando regras
manuais não descritas).

```hcl
# Grafana - restrito ao IP do administrador (regra trazida da Console para o codigo)
ingress_security_rules {
  protocol = "6"
  source   = var.ssh_allowed_cidr
  tcp_options {
    min = 3000
    max = 3000
  }
}
```

Confirmado com `terraform plan` → `No changes. Your infrastructure
matches the configuration.` após o `apply`.

### 3. Eliminar credenciais em texto simples do script

`scripts/export_zabbix_metrics.py` passou a ler a password do Zabbix de
uma variável de ambiente, em vez de a ter escrita no ficheiro:

```python
import os
ZABBIX_PASSWORD = os.environ.get("ZABBIX_PASSWORD")

if not ZABBIX_PASSWORD:
    raise RuntimeError("Define a variável de ambiente ZABBIX_PASSWORD antes de correr este script.")
```

## Risco identificado e ainda pendente

Durante a validação da correcção acima, confirmou-se que a conta `Admin`
do Zabbix ainda usa a **password por omissão da imagem oficial**
(`zabbix-appliance`). Isto é uma falha de segurança real e conhecida —
qualquer scanner automático tenta essa credencial em primeiro lugar.

**Acção pendente, não concluída nesta sessão:** mudar a password do
utilizador `Admin` do Zabbix (Users → Admin → Change password).

## Consequências

- **Positivo:** a superfície de ataque de rede fica reduzida a um único
  IP conhecido, em vez de aberta ao mundo.
- **Positivo:** o código Terraform volta a ser a fonte de verdade real da
  infra-estrutura, eliminando o risco de uma regra manual ser apagada por
  surpresa num `apply` futuro.
- **Positivo:** nenhuma credencial fica versionada em texto simples no
  repositório.
- **Trade-off aceite:** um único IP de administrador é mais simples de
  gerir, mas menos resiliente a mudanças de rede — aceite por agora,
  com o suporte a múltiplos IPs registado como melhoria futura.
- **Risco em aberto:** password por omissão do Zabbix ainda activa — a
  fechar antes deste laboratório ser considerado "hardened" por completo.

## Referências

- `ADR-002-network-topology.md` (decisão original de `0.0.0.0/0`)
- `terraform/network/main.tf` (Security List)
- `scripts/export_zabbix_metrics.py`
