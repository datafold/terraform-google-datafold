resource "google_project_iam_custom_role" "clickhouse" {
  role_id = "${replace(var.deployment_name, "-", "_")}_clickhouse_backup"
  title   = "${var.deployment_name}-clickhouse-backup"
  permissions = [
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list"
  ]
}

resource "google_service_account" "clickhouse" {
  account_id   = "${var.deployment_name}-${local.legacy_ch}-sa"
  display_name = "${var.deployment_name}-${local.legacy_ch}-sa"
}

resource "google_project_iam_member" "clickhouse" {
  project = var.project_id
  role    = resource.google_project_iam_custom_role.clickhouse.name
  member  = "serviceAccount:${google_service_account.clickhouse.email}"
}

