#  ┏━╸╻  ╻┏━╸╻┏ ╻ ╻┏━┓╻ ╻┏━┓┏━╸   ┏┓ ┏━┓┏━╸╻┏ ╻ ╻┏━┓
#  ┃  ┃  ┃┃  ┣┻┓┣━┫┃ ┃┃ ┃┗━┓┣╸    ┣┻┓┣━┫┃  ┣┻┓┃ ┃┣━┛
#  ┗━╸┗━╸╹┗━╸╹ ╹╹ ╹┗━┛┗━┛┗━┛┗━╸   ┗━┛╹ ╹┗━╸╹ ╹┗━┛╹

locals {
  legacy_sa = var.legacy_naming ? "ServiceAccount" : "sa"
  legacy_ch = var.legacy_naming ? "clickhouse" : "ch"
}

resource "google_storage_bucket" "clickhouse_backup" {
  name                        = "${var.deployment_name}-${var.clickhouse_gcs_bucket}"
  location                    = var.provider_region
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 14
    }
    action {
      type = "Delete"
    }
  }
}
