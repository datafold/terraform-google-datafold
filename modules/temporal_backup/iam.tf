resource "google_project_iam_custom_role" "temporal_backup" {
  role_id = "${replace(var.deployment_name, "-", "_")}_temporal_pg_backup"
  title   = "${var.deployment_name}-temporal-pg-backup"
  permissions = [
    "storage.buckets.get",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
  ]
}

resource "google_service_account" "temporal_backup" {
  account_id   = "${var.deployment_name}-temporal-pg-sa"
  display_name = "${var.deployment_name}-temporal-pg-sa"
}

resource "google_project_iam_member" "temporal_backup" {
  project = var.project_id
  role    = google_project_iam_custom_role.temporal_backup.name
  member  = "serviceAccount:${google_service_account.temporal_backup.email}"
}

resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.temporal_backup.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.temporal_postgres_namespace}/postgres-pod]"
}
