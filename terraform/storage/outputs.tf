output "bucket_name" {
  value = oci_objectstorage_bucket.aiops_data.name
}

output "namespace" {
  value = data.oci_objectstorage_namespace.ns.namespace
}
