############################################
# Sessão 3-4 — OCI Data Science
# Project + Notebook Session para explorar os dados
# exportados do Zabbix e treinar o modelo de anomalias
############################################

resource "oci_datascience_project" "aiops_project" {
  compartment_id = var.compartment_id
  display_name   = "aiops-lab-project"
  description    = "Projecto OCI Data Science do laboratorio AIOps"
}

resource "oci_datascience_notebook_session" "aiops_notebook" {
  compartment_id = var.compartment_id
  project_id     = oci_datascience_project.aiops_project.id
  display_name   = "aiops-notebook-manual"

  notebook_session_config_details {
    shape                      = var.notebook_shape
    block_storage_size_in_gbs  = var.block_storage_gb

    notebook_session_shape_config_details {
      ocpus         = var.notebook_ocpus
      memory_in_gbs = var.notebook_memory_gb
    }
  }
}
