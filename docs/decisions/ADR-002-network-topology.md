# ADR-002: Instância na sub-rede pública (em vez de privada + bastion)

Data: 2026-11-04
Estado: aceite — a rever na Sessão 6 (Hardening & Segurança)

## Contexto

A instância que corre o Zabbix e o Zabbix Agent precisa de ser acessível por
SSH para administração e pela interface web do Zabbix para visualização.

## Decisão

Na fase inicial (Sessões 0-5), a instância fica numa sub-rede pública com IP
público directo, com acesso SSH e HTTP restrito por `ssh_allowed_cidr`.

## Alternativas consideradas

- **Sub-rede privada + bastion host**: mais seguro e mais próximo de um
  ambiente de produção real, mas adiciona complexidade (mais um recurso a
  gerir, mais custo) antes de haver algo a proteger.
- **Sub-rede privada + Bastion Service da OCI (sem instância extra)**: boa
  alternativa intermédia — considerada para a Sessão 6.

## Consequências

- Mais simples de operar nas sessões iniciais, mas superfície de ataque maior
  enquanto `ssh_allowed_cidr` não é restringido ao IP pessoal.
- Fica registado como item de acção explícito para a Sessão 6: restringir o
  CIDR e avaliar migrar para o Bastion Service da OCI.
