provider "google" {
  project = local.project_id
  region  = local.provider_region
  zone    = local.provider_azs[0]
}

data "google_container_cluster" "cluster" {
  name     = data.sops_file.infra.data["global.clusterName"]
  location = local.provider_azs[0]
  project  = local.project_id
}
