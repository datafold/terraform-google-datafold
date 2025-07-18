output "clickhouse_gcs_bucket" {
  value = resource.google_storage_bucket.clickhouse_backup.name
}

output "clickhouse_backup_sa" {
  value = resource.google_service_account.clickhouse.email
}
