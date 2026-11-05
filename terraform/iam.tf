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
