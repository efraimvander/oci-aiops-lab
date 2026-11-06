# ADR-004: Autenticação do Notebook Session via Resource Principal (e o caso BucketNotFound intermitente)

## Status

Aceite — implementado e validado em produção (Sessão 3, 06/11/2026).

## Contexto

O Notebook Session do OCI Data Science (Sessão 3) precisa de ler ficheiros do
Object Storage (CSV com métricas exportadas do Zabbix) a partir de código
Python dentro do próprio notebook.

Havia duas formas possíveis de autenticar essa chamada:

1. **Chave API pessoal** (`oci.config.from_file()`), copiando o ficheiro de
   configuração e a chave privada para dentro do ambiente do notebook.
2. **Resource Principal**, em que o próprio Notebook Session recebe uma
   identidade da OCI, sem nenhuma credencial transportada manualmente.

A opção 1 foi testada primeiro por ser o caminho "óbvio", mas falhou de
imediato com `ConfigFileNotFound` — o ambiente cloud do Notebook Session não
tem (nem deve ter) um `~/.oci/config` local. Isto confirmou que a opção 2 é
também a única coerente com o resto do projecto, que segue infra-estrutura
como código e o princípio de least privilege (nenhuma chave é copiada para
dentro de recursos que não precisam de a guardar).

## Decisão

Usar **Resource Principal** para toda a comunicação do Notebook Session com
o Object Storage, implementado com três peças geridas por Terraform
(`terraform/iam.tf`):

```hcl
resource "oci_identity_dynamic_group" "aiops_notebook_dynamic_group" {
  compartment_id = var.tenancy_ocid
  name           = "aiops-notebook-dynamic-group"
  matching_rule  = "ALL {resource.type = 'datasciencenotebooksession', resource.compartment.id = '${oci_identity_compartment.aiops_lab.id}'}"
}

resource "oci_identity_policy" "aiops_notebook_policy" {
  compartment_id = var.tenancy_ocid
  name           = "aiops-notebook-policy"
  statements = [
    "Allow dynamic-group aiops-notebook-dynamic-group to manage objects in compartment aiops-lab"
  ]
  depends_on = [oci_identity_dynamic_group.aiops_notebook_dynamic_group]
}
```

E, no código Python do notebook:

```python
signer = oci.auth.signers.get_resource_principals_signer()
object_storage = oci.object_storage.ObjectStorageClient(config={}, signer=signer)
```

## Problema encontrado: BucketNotFound intermitente

Depois de aplicar a Policy e confirmar que a leitura funcionava, o mesmo
erro `404 BucketNotFound` ("does not exist ... or you are not authorized")
voltou a acontecer após o kernel do Jupyter perder a ligação e ser
reiniciado (Kernel → Restart Kernel).

Hipóteses verificadas e eliminadas, uma a uma, directamente na Console
(não apenas no `terraform state`, que não garante que a realidade aplicada
corresponde ao código):

| # | Hipótese | Verificação | Resultado |
|---|----------|-------------|-----------|
| 1 | Matching Rule errada | Identity & Security → Domains → Default → Dynamic groups | ✅ Correcta |
| 2 | Texto da Policy errado | Identity & Security → Policies → aiops-notebook-policy | ✅ Correcto |
| 3 | Bucket fora do compartment coberto | Object Storage → Buckets, filtro por compartment | ✅ `aiops-lab-data` está em `aiops-lab` |
| 4 | Compartments duplicados (por causa do `terraform import` feito na Sessão 1) | `oci iam compartment list --all --compartment-id-in-subtree true --query "data[?name=='aiops-lab']..."` | ✅ Apenas um compartment, mesmo OCID em todo o lado |

Com tudo na configuração confirmado correcto, a causa real estava noutro
sítio: o **Resource Principal assenta num certificado de curta duração,
emitido quando o Notebook Session arranca (ou é reactivado)**, renovado em
segundo plano enquanto a sessão está `Active`. Um `Restart Kernel` reinicia
apenas o processo Python — não renova esse certificado. Se o certificado
ficar momentaneamente inconsistente, o erro de autorização reaparece de
forma imprevisível, mesmo com a configuração de IAM 100% correcta.

**Solução:** desactivar e reactivar o próprio Notebook Session (Data
Science → Projects → aiops-lab-project → aiops-notebook-manual →
Deactivate, esperar por `Inactive`, depois Activate) — não só o kernel.
Isto força a emissão de um certificado novo, já alinhado com a Policy
actual. Depois disso, a leitura do CSV passou a funcionar de forma
consistente.

## Consequências

- **Positivo:** nenhuma chave API circula dentro do Notebook Session;
  acesso ao Object Storage é concedido e revogável apenas através de
  Dynamic Group + Policy, versionados em Terraform.
- **Positivo:** o processo de diagnóstico (eliminar Matching Rule → Policy
  → compartment do recurso → duplicação de nomes → ciclo de vida do
  certificado) fica documentado e reutilizável para qualquer outro recurso
  OCI autenticado por Resource Principal (Functions, Data Flow, etc.).
- **Atenção futura:** um erro `BucketNotFound`/`NamespaceNotFound` com
  Resource Principal nem sempre significa configuração de IAM errada — pode
  ser necessário reactivar o recurso, não apenas reiniciar o processo/kernel.
  Este comportamento não está claramente documentado nas fontes públicas da
  Oracle.
- **Trade-off aceite:** desactivar/reactivar o Notebook Session demora mais
  do que um simples restart de kernel, mas é o único passo que garante um
  certificado de identidade actualizado.

## Referências

- Documento de troubleshooting completo: `Troubleshooting_ResourcePrincipal_ObjectStorage.docx`
- `terraform/iam.tf` (Dynamic Group + Policy)
- Sessão 3 do programa `oci-aiops-lab`
