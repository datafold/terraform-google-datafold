locals {
  azs = coalescelist(
    var.provider_azs,
    data.google_compute_zones.available.names
  )
  vpc_network = coalesce(
    one(resource.google_compute_network.vpc[*].name),
    one(data.google_compute_network.this[*].name)
  )
  vpc_selflink = coalesce(
    one(resource.google_compute_network.vpc[*].self_link),
    one(data.google_compute_network.this[*].self_link)
  )
  vpc_subnetwork = coalesce(
    one(resource.google_compute_subnetwork.default[*].self_link),
    one(data.google_compute_network.this[*].subnetworks_self_links[0])
  )
  subnets = (
    var.deploy_vpc_flow_logs ?
    [{
      subnet_name               = "${var.deployment_name}-private"
      subnet_ip                 = var.vpc_cidr
      subnet_region             = var.provider_region
      subnet_private_access     = "true"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = var.vpc_flow_logs_interval
      subnet_flow_logs_sampling = var.vpc_flow_logs_sampling
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
    }] :
    [{
      subnet_name           = "${var.deployment_name}-private"
      subnet_ip             = var.vpc_cidr
      subnet_region         = var.provider_region
      subnet_private_access = "true"
    }]
  )
}

#  ┏━╸╻ ╻╻┏━┓╺┳╸╻┏┓╻┏━╸   ╻ ╻┏━┓┏━╸
#  ┣╸ ┏╋┛┃┗━┓ ┃ ┃┃┗┫┃╺┓   ┃┏┛┣━┛┃
#  ┗━╸╹ ╹╹┗━┛ ╹ ╹╹ ╹┗━┛   ┗┛ ╹  ┗━╸

data "google_compute_network" "this" {
  count = var.vpc_id != "" ? 1 : 0
  name  = var.vpc_id
}

#  ┏┓╻┏━╸╻ ╻   ╻ ╻┏━┓┏━╸
#  ┃┗┫┣╸ ┃╻┃   ┃┏┛┣━┛┃
#  ╹ ╹┗━╸┗┻┛   ┗┛ ╹  ┗━╸

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.provider_region
  status  = "UP"
}

resource "google_compute_network" "vpc" {
  name                    = var.deployment_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name = "${var.deployment_name}-private"

  ip_cidr_range            = var.vpc_cidr
  private_ip_google_access = true
  network                  = google_compute_network.vpc.self_link

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "privaterouter" {
  project = var.project_id
  name    = "${var.deployment_name}-nat-router"
  network = google_compute_network.vpc.self_link
  region  = var.provider_region
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.2"
  project_id = var.project_id
  region     = var.provider_region
  router     = google_compute_router.privaterouter.name
  name       = "${var.deployment_name}-nat"

}
