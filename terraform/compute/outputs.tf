output "public_ip" {
  value = oci_core_instance.aiops_vm.public_ip
}

output "instance_id" {
  value = oci_core_instance.aiops_vm.id
}
