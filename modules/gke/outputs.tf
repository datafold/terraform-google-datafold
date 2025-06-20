output "cluster_name" {
  value = resource.google_container_cluster.default.name
}

output "dfshell_service_account_email" {
  value = google_service_account.dfshell.email
}

output "dfshell_service_account_unique_id" {
  value = google_service_account.dfshell.unique_id
}
