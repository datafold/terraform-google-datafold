# Define the service account for the cluster nodes
resource "google_service_account" "gke_service_account" {
  account_id   = "gke-service-account"
  display_name = "GKE Service Account"
}

# Assign the necessary roles to the service account
resource "google_project_iam_member" "gke_service_account_logging" {
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
  project = var.project_id
}

resource "google_project_iam_member" "gke_service_account_monitoring" {
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
  project = var.project_id
}

resource "google_project_iam_member" "gke_service_account_storage" {
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_service_account.email}"
  project = var.project_id
}
