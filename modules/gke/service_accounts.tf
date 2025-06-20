resource "google_service_account" "dfshell" {
  account_id   = "dfshell"
  display_name = "dfshell Service Account"
}

resource "google_service_account_iam_binding" "dfshell_k8s_workload_identity" {
  service_account_id = google_service_account.dfshell.name
  role               = "roles/iam.workloadIdentityUser"

  members = ["serviceAccount:${var.project_id}.svc.id.goog[${var.deployment_name}/${var.dfshell_service_account_name}]"]
}

