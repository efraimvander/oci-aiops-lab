# ADR-003: Resolução de problemas na instalação do Zabbix (appliance + agent)

Data: 2026-11-05
Estado: aceite

## Contexto

Depois de a infra-estrutura base (compartment, VCN, instância) estar criada via
Terraform, era preciso pôr o Zabbix a monitorizar a própria instância: o
Zabbix Server/frontend a correr em container (via cloud-init) e o Zabbix
Agent nativo a reportar métricas locais. Nenhum destes passos correu à
primeira — os problemas abaixo não tinham resposta directa e pronta na
documentação oficial nem em pesquisas rápidas, por isso ficam registados em
detalhe.

## Decisão

Manter a arquitectura original (Zabbix appliance em container + agent nativo
no host), resolvendo cada bloqueio encontrado em vez de mudar de abordagem,
e documentar cada causa raiz para referência futura.

## Problemas encontrados e soluções

### 1. Repositório oficial do Zabbix 6.4 devolve 404
**Causa:** o Zabbix 6.4 é uma versão de suporte a curto prazo (STS) e já foi
retirado do `repo.zabbix.com`.
**Solução:** usar o repositório `ol8_developer_EPEL` da própria Oracle em vez
do repositório oficial do Zabbix.

### 2. Shape ARM (aarch64) sem pacotes Zabbix disponíveis
**Causa:** a instância ficou com o shape `VM.Standard.A1.Flex` (ARM) devido a
falta de capacidade Always Free no shape x86_64 original. Nem o repositório
oficial do Zabbix nem o EPEL da Oracle têm pacotes Zabbix compilados para
ARM nesta combinação de SO (Oracle Linux 8).
**Solução:** recriar a instância com um shape x86_64 (`VM.Standard.E4.Flex`).

### 3. Nome do pacote e caminho de configuração não-standard
**Causa:** o repositório EPEL da Oracle só disponibiliza `zabbix7.0-agent`
(agente clássico em C), não `zabbix7.0-agent2`. Este pacote instala o
ficheiro de configuração em `/etc/zabbix_agentd.conf`, fora da pasta
`/etc/zabbix/` onde é mais comum encontrá-lo noutras distribuições.
**Solução:** confirmar sempre o caminho real com `rpm -ql zabbix7.0-agent |
grep conf` antes de assumir a localização.

### 4. "docker" no Oracle Linux é na verdade Podman
**Causa:** o pacote "docker" do Oracle Linux instala o Podman por baixo, com
um alias que traduz comandos `docker` para `podman`. A sintaxe de alguns
comandos é mais rígida na ordem dos argumentos (ex: flags antes do nome do
container em `docker logs`).
**Solução:** tratar `docker` como Podman ao interpretar comportamentos
inesperados, e confirmar a ordem dos argumentos quando um comando falha.

### 5. Mapeamento de porta incorrecto (8080 em vez de 80)
**Causa:** o container `zabbix/zabbix-appliance` expõe o frontend
internamente na porta 80, não 8080. O mapeamento inicial (`-p 80:8080`)
fazia o host escutar na porta certa, mas apontava para a porta errada dentro
do container — resultado: "Connection refused" mesmo com o nginx a correr.
**Solução:** recriar o container com `-p 80:80 -p 443:443 -p 10051:10051`.

### 6. Versão do Zabbix mais antiga do que esperado (4.4.6)
**Causa:** a imagem `zabbix/zabbix-appliance:latest` no Docker Hub não
acompanha as versões mais recentes do Zabbix; trouxe a versão 4.4.6
(lançada em 2019). Os nomes de templates mudaram a partir da v5.0 ("Linux by
Zabbix agent" só existe a partir daí).
**Solução imediata:** usar o template "Template OS Linux", compatível com a
v4.4. **Melhoria futura:** montar a stack com imagens oficiais separadas
(server + web + db) fixadas explicitamente na versão 7.0 LTS.

### 7. "Zabbix agent is not available" após criar o host
**Causa:** o Zabbix server corre dentro do container, numa rede isolada
(Podman, `10.88.0.0/16`). Configurar o host com IP `127.0.0.1` apontava para
o próprio container, não para a VM onde o agent estava instalado.
**Solução:** apontar a interface do host, no Zabbix web, para o IP privado
real da VM (ex: `10.0.1.3`), e alargar `Server=` no `zabbix_agentd.conf` para
aceitar ligações vindas da rede do container.

### 8. Firewall local (firewalld) a bloquear a porta do agent
**Causa:** o `firewalld`, activo por omissão no Oracle Linux 8, bloqueia
portas não explicitamente abertas, independentemente da Security List da
OCI já permitir o tráfego — são duas camadas de firewall distintas.
**Solução:** `firewall-cmd --permanent --add-port=10050/tcp && firewall-cmd
--reload`.

## Alternativas consideradas

- **Trocar para uma stack Zabbix oficial multi-container (server + web + db
  separados)** em vez do appliance tudo-em-um: mais representativo de um
  ambiente de produção real, mas adiado para não bloquear o progresso nesta
  fase do laboratório. Fica como melhoria candidata para uma sessão futura.
- **Usar Ansible para automatizar toda esta instalação**, eliminando os
  passos manuais: fica como evolução natural depois do laboratório validado
  manualmente pelo menos uma vez.

## Consequências

- O ambiente ficou funcional com uma versão de Zabbix mais antiga (4.4.6) do
  que o ideal — aceitável para o âmbito deste laboratório, mas documentado
  como dívida técnica.
- O `cloud-init.yaml` do módulo `compute` precisa de ser actualizado com o
  mapeamento de porta correcto (80:80) e os passos EPEL corrigidos, para que
  uma recriação futura da instância não repita os mesmos problemas.
- Nenhum destes problemas tinha uma resposta directa e pronta online — a
  investigação caso a caso (logs, exec dentro do container, inspecção de
  rede) foi o que resolveu cada um, não uma única fonte.
