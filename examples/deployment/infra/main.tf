#  ┏┳┓┏━┓╻┏┓╻
#  ┃┃┃┣━┫┃┃┗┫
#  ╹ ╹╹ ╹╹╹ ╹



#  ┏━╸┏━╸┏━┓
#  ┃╺┓┃  ┣━┛
#  ┗━┛┗━╸╹

module "gcp" {
  source  = "datafold/datafold/google"
  version = "1.2.5"

  providers = {
    google = google
  }

  # Common
  deployment_name = local.deployment_name
  environment     = local.environment
  common_tags     = local.common_tags
  project_id      = local.project_id

  # Provider
  provider_region = local.provider_region
  provider_azs    = local.provider_azs

  # Load Balancer
  domain_name        = "datafold.acme.com"
  create_ssl_cert    = true
  ssl_cert_name      = local.customer_name
  lb_app_rules       = local.lb_app_rules
  deploy_neg_backend = true

  # Virtual Private Cloud
  whitelisted_ingress_cidrs = local.lb_whitelisted_ingress_cidrs
  whitelisted_egress_cidrs = concat(
    local.github_cidrs
  )
  deploy_vpc_flow_logs = true

  # Clickhouse
  clickhouse_data_disk_size = 50

  # k8s
  k8s_authorized_networks = local.authorized_networks
  k8s_cluster_version     = "1.28.11-gke.1260000"
}
