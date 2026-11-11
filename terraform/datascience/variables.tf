variable "compartment_id" {
  description = "OCID do compartment onde o projecto e notebook session sao criados."
  type        = string
}

variable "notebook_shape" {
  description = "Shape do Notebook Session."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "notebook_ocpus" {
  description = "Numero de OCPUs do notebook session (shape flex)."
  type        = number
  default     = 1
}

variable "notebook_memory_gb" {
  description = "Memoria em GB do notebook session (shape flex)."
  type        = number
  default     = 16
}

variable "block_storage_gb" {
  description = "Tamanho do block storage associado ao notebook session, em GB."
  type        = number
  default     = 50
}