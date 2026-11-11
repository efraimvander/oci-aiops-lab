############################################
# Sessão 0 — Fundação & Governança
# Compartment, grupo IAM e policy least-privilege
############################################

resource "oci_identity_compartment" "aiops_lab" {
  compartment_id = var.tenancy_ocid
  name           = var.compartment_name
  description    = "Compartment dedicado ao projecto OCI AIOps Lab"
  enable_delete  = true
}

resource "oci_identity_group" "aiops_admins" {
  compartment_id = var.tenancy_ocid # grupos existem sempre ao nível da tenancy
  name           = "aiops-lab-admins"
  description    = "Administradores do projecto aiops-lab"
}

resource "oci_identity_policy" "aiops_policy" {
  compartment_id = var.tenancy_ocid
  name           = "aiops-lab-policy"
  description    = "Acesso restrito ao compartment aiops-lab (least privilege)"

  statements = [
    "Allow group aiops-lab-admins to manage all-resources in compartment ${var.compartment_name}"
  ]

  depends_on = [oci_identity_compartment.aiops_lab]
}

# Lembrete: para te adicionares a este grupo, vai à consola em
# Identity & Security -> Domains -> Default -> Groups -> aiops-lab-admins -> Add User
# (o Terraform cria o grupo, mas adicionar-te a ti próprio é um passo manual de segurança deliberado)


resource "oci_identity_dynamic_group" "aiops_notebook_dynamic_group" {
  compartment_id = var.tenancy_ocid # dynamic groups vivem sempre na raiz (tenancy)
  name           = "aiops-notebook-dynamic-group"
  description    = "Cobre os Notebook Sessions do Data Science dentro do compartment aiops-lab"
  matching_rule  = "ALL {resource.type = 'datasciencenotebooksession', resource.compartment.id = '${oci_identity_compartment.aiops_lab.id}'}"
}

resource "oci_identity_policy" "aiops_notebook_policy" {
  compartment_id = var.tenancy_ocid
  name           = "aiops-notebook-policy"
  description    = "Permite aos Notebook Sessions aceder ao Object Storage do compartment aiops-lab"

  statements = [
    "Allow dynamic-group aiops-notebook-dynamic-group to manage objects in compartment ${var.compartment_name}"
  ]

  depends_on = [oci_identity_dynamic_group.aiops_notebook_dynamic_group]
}
