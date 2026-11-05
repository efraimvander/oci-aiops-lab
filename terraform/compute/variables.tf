variable "compartment_id" {
  description = "OCID do compartment onde a instância é criada."
  type        = string
}

variable "subnet_id" {
  description = "OCID da sub-rede onde a instância fica (vem do módulo network)."
  type        = string
}

variable "ssh_public_key" {
  description = "Chave pública SSH para aceder à instância."
  type        = string
}

variable "instance_shape" {
  description = "Shape da instância (ex: VM.Standard.E2.1.Micro ou VM.Standard.A1.Flex)."
  type        = string
}
