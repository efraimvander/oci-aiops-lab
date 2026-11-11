output "project_id" {
  value = oci_datascience_project.aiops_project.id
}

output "notebook_session_id" {
  value = oci_datascience_notebook_session.aiops_notebook.id
}

output "notebook_session_url" {
  value       = oci_datascience_notebook_session.aiops_notebook.notebook_session_url
  description = "Abre este link no browser para acederes ao Jupyter do Notebook Session."
}
