provider "google" {
  project = local.project_id
  region  = local.provider_region
  zone    = local.provider_azs[0]
}

provider "google-beta" {
  project = local.project_id
  region  = local.provider_region
  zone    = local.provider_azs[0]
}

