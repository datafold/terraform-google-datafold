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
  name    = "${var.deployment_name}"
  network = google_compute_network.vpc.self_link
  region  = var.provider_region

  dynamic "bgp" {
    for_each = var.cloud_router_bgp != null ? [var.cloud_router_bgp] : []
    content {
      asn = var.cloud_router_bgp.asn

      advertise_mode     = lookup(var.cloud_router_bgp, "advertise_mode", "DEFAULT")
      advertised_groups  = lookup(var.cloud_router_bgp, "advertised_groups", null)
      keepalive_interval = lookup(var.cloud_router_bgp, "keepalive_interval", null)

      dynamic "advertised_ip_ranges" {
        for_each = lookup(var.cloud_router_bgp, "advertised_ip_ranges", [])
        content {
          range       = advertised_ip_ranges.value.range
          description = lookup(advertised_ip_ranges.value, "description", null)
        }
      }
    }
  }
}

module "cloud-nat" {
  count      = length(var.cloud_router_nats) > 0 ? 0 : 1
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 5.3.0"
  project_id = var.project_id
  region     = var.provider_region
  router     = google_compute_router.privaterouter.name
  name       = "${var.deployment_name}-nat"

}

resource "google_compute_router_nat" "nats" {
  for_each = {
    for n in var.cloud_router_nats :
    n.name => n
  }

  name                                = each.value.name
  project                             = google_compute_router.privaterouter.project
  router                              = google_compute_router.privaterouter.name
  region                              = google_compute_router.privaterouter.region
  nat_ip_allocate_option              = coalesce(each.value.nat_ip_allocate_option, length(each.value.nat_ips) > 0 ? "MANUAL_ONLY" : "AUTO_ONLY")
  source_subnetwork_ip_ranges_to_nat  = coalesce(each.value.source_subnetwork_ip_ranges_to_nat, "ALL_SUBNETWORKS_ALL_IP_RANGES")
  nat_ips                             = each.value.nat_ips
  min_ports_per_vm                    = each.value.min_ports_per_vm
  max_ports_per_vm                    = each.value.max_ports_per_vm
  udp_idle_timeout_sec                = each.value.udp_idle_timeout_sec
  icmp_idle_timeout_sec               = each.value.icmp_idle_timeout_sec
  tcp_established_idle_timeout_sec    = each.value.tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec     = each.value.tcp_transitory_idle_timeout_sec
  tcp_time_wait_timeout_sec           = each.value.tcp_time_wait_timeout_sec
  enable_endpoint_independent_mapping = each.value.enable_endpoint_independent_mapping
  enable_dynamic_port_allocation      = each.value.enable_dynamic_port_allocation

  log_config {
    enable = each.value.log_config.enable
    filter = each.value.log_config.filter
  }

  dynamic "subnetwork" {
    for_each = each.value.subnetworks
    content {
      name                     = subnetwork.value.name
      source_ip_ranges_to_nat  = subnetwork.value.source_ip_ranges_to_nat
      secondary_ip_range_names = subnetwork.value.secondary_ip_range_names
    }
  }
}