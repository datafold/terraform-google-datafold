output "clickhouse_gcs_bucket" {
  value = resource.google_storage_bucket.clickhouse_backup.name
}

output "clickhouse_backup_sa" {
  value = var.clickhouse_get_backup_sa_from_secrets_yaml ? var.clickhouse_backup_sa_key : one(resource.google_service_account_key.clickhouse[*].private_key)
}
