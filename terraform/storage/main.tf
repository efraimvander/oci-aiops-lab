terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}
############################################
# Sessão 3 — Object Storage (data lake do laboratório)
# Criado já agora para o bucket existir desde o início;
# só vais usá-lo activamente na Sessão 3.
############################################

resource "oci_objectstorage_bucket" "aiops_data" {
  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "aiops-lab-data"
  access_type    = "NoPublicAccess"
  storage_tier   = "Standard"
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_id
}

