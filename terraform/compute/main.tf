terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}
############################################
# Sessão 1 — Instância Compute (Always Free)
# Oracle Linux 8 + cloud-init (Docker, Zabbix, stress-ng)
############################################

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

data "oci_core_images" "oracle_linux" {
  compartment_id           = var.compartment_id
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "aiops_vm" {
  compartment_id      = var.compartment_id
  availability_domain  = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name         = "aiops-vm"
  shape                = var.instance_shape

  # Shapes "Flex" (ex: VM.Standard.A1.Flex) exigem shape_config.
  # Para shapes fixos (ex: VM.Standard.E2.1.Micro) este bloco é ignorado pelo provider.
  dynamic "shape_config" {
    for_each = strcontains(var.instance_shape, "Flex") ? [1] : []
    content {
      ocpus         = 1
      memory_in_gbs = 6
    }
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
    display_name     = "aiops-vm-vnic"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.oracle_linux.images[0].id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }
}

