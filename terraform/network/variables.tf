variable "compartment_id" {
  description = "OCID do compartment onde a rede é criada."
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "Range de IPs autorizado a aceder por SSH e à interface web do Zabbix."
  type        = string
}
