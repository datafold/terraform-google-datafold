output "temporal_gcs_bucket" {
  value = google_storage_bucket.temporal_backup.name
}

output "temporal_backup_sa" {
  value = google_service_account.temporal_backup.email
}
