variable "compartment_id" {
  description = "OCID do compartment onde a rede é criada."
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "Lista de IPs/CIDRs autorizados a aceder por SSH e às interfaces web do Zabbix/Grafana (ex: casa, empresa)."
  type        = list(string)
}
