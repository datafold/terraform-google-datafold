#  ┏━╸╻┏━┓┏━╸╻ ╻┏━┓╻  ╻
#  ┣╸ ┃┣┳┛┣╸ ┃╻┃┣━┫┃  ┃
#  ╹  ╹╹┗╸┗━╸┗┻┛╹ ╹┗━╸┗━╸

module "firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  version      = "10.0.0"
  project_id   = var.project_id
  network_name = local.vpc_network

  rules = [
    {
      name                    = "${var.deployment_name}-allow-ingress-iap"
      description             = "Allow ingress from IAP for SSH"
      direction               = "INGRESS"
      priority                = 999
      ranges                  = ["35.235.240.0/20"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
      }, {
      name                    = "${var.deployment_name}-allow-ingress-load-balancer-range"
      description             = "Ingress for some range of Google LB's"
      direction               = "INGRESS"
      priority                = 999
      ranges                  = ["34.96.0.0/20", "34.127.192.0/18"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [{
        protocol = "tcp"
        ports    = ["80", "443"]
      }]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
      }, {
      name                    = "${var.deployment_name}-allow-ingress-lb-health-checks"
      description             = "Ingress for GCP LB traffic and health checks."
      direction               = "INGRESS"
      priority                = 999
      ranges                  = ["35.191.0.0/16", "130.211.0.0/22"]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [{
        protocol = "tcp"
        ports    = ["80"]
      }]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
      }, {
      name                    = "${var.deployment_name}-allow-internal-all-ingress"
      description             = "Allow all internal ingress on the VPC CIDR"
      direction               = "INGRESS"
      priority                = null
      ranges                  = [var.vpc_cidr]
      source_tags             = null
      source_service_accounts = null
      target_tags             = null
      target_service_accounts = null
      allow = [{
        protocol = "tcp"
        ports    = null
        }, {
        protocol = "udp"
        ports    = null
      }]
      deny = []
      log_config = {
        metadata = "INCLUDE_ALL_METADATA"
      }
    }
  ]
}