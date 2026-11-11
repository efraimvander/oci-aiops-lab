output "compartment_id" {
  value = oci_identity_compartment.aiops_lab.id
}

output "vcn_id" {
  value = module.network.vcn_id
}

output "instance_public_ip" {
  value       = module.compute.public_ip
  description = "Acede ao Zabbix em http://<este-ip> (login inicial Admin/zabbix) e por SSH com: ssh opc@<este-ip>"
}

output "bucket_name" {
  value = module.storage.bucket_name
}


output "notebook_session_url" {
  value       = module.datascience.notebook_session_url
  description = "Abre este link para acederes ao Jupyter Notebook"
}
