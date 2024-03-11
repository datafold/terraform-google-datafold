resource "google_compute_disk" "clickhouse_data" {
  project = var.project_id
  zone    = module.networking.azs[0]
  name    = "${var.deployment_name}-clickhouse-data"
  size    = var.clickhouse_data_disk_size
  type    = var.mig_disk_type

  depends_on = [
    module.project_factory_project_services
  ]

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}

resource "google_compute_disk" "clickhouse_logs" {
  project = var.project_id
  zone    = module.networking.azs[0]
  name    = "${var.deployment_name}-clickhouse-logs"
  size    = var.clickhouse_data_disk_size
  type    = var.mig_disk_type

  depends_on = [
    module.project_factory_project_services
  ]

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}

resource "google_compute_disk" "redis_data" {
  project = var.project_id
  zone    = module.networking.azs[0]
  name    = "${var.deployment_name}-redis-data"
  size    = var.redis_data_size
  type    = var.mig_disk_type

  depends_on = [
    module.project_factory_project_services
  ]

  lifecycle {
    ignore_changes = [
      labels,
    ]
  }
}
