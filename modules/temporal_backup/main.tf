resource "google_storage_bucket" "temporal_backup" {
  name                        = "${var.deployment_name}-${var.temporal_gcs_bucket}"
  location                    = var.provider_region
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = var.backup_lifecycle_expiration_days
    }
    action {
      type = "Delete"
    }
  }
}
