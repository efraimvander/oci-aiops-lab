############################################
# Raiz do projecto — liga os módulos network, compute e storage
# ao compartment criado em iam.tf
############################################

module "network" {
  source = "./network"

  compartment_id   = oci_identity_compartment.aiops_lab.id
  ssh_allowed_cidr = var.ssh_allowed_cidr
}

module "compute" {
  source = "./compute"

  compartment_id  = oci_identity_compartment.aiops_lab.id
  subnet_id       = module.network.public_subnet_id
  ssh_public_key  = var.ssh_public_key
  instance_shape  = var.instance_shape
}

module "storage" {
  source = "./storage"

  compartment_id = oci_identity_compartment.aiops_lab.id
}
