#  ┏┳┓┏━┓╻┏┓╻
#  ┃┃┃┣━┫┃┃┗┫
#  ╹ ╹╹ ╹╹╹ ╹


locals {
  database_name = module.gcp.postgres_database_name
}

module "gcp" {
  source  = "datafold/datafold/google"
  version = "1.6.0"

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
  domain_name        = "datafold.example.com"
  create_ssl_cert    = true
  ssl_cert_name      = local.customer_name
  deploy_lb          = false  # Load balancer disabled by default
  initial_apply_complete = true

  # Virtual Private Cloud
  whitelisted_ingress_cidrs = ["0.0.0.0/0"]
  whitelisted_egress_cidrs = concat(
    ["0.0.0.0/0"],
    local.github_cidrs
  )
  vpc_cidr = "10.0.0.0/16"
  deploy_vpc_flow_logs = true

  # Clickhouse
  clickhouse_gcs_bucket = "clickhouse-backups-example"
  clickhouse_data_disk_size = 50

  # Redis
  redis_data_size = 50

  # Database
  database_version = "POSTGRES_17"
  apply_major_upgrade = false
  postgres_max_allocated_storage = 100

  # k8s
  k8s_authorized_networks = local.authorized_networks
  k8s_cluster_version = local.k8s_version

  managed_node_grp1 = {
    min_size     = 1
    max_size     = 2
    desired_size = 1

    instance_types  = ["e2-standard-8"]
    capacity_type   = "ON_DEMAND"
    use_name_prefix = false
    name            = "datafold-nodegroup"

    force_update_version = true
    update_config        = { "max_unavailable_percentage" : 50 }
  }

  # For larger deployments, you can configure a second node pool "managed_node_grp2"
  # managed_node_grp2 = {
  #   min_size     = 0
  #   max_size     = 1
  #   desired_size = 0
  #
  #   instance_types  = ["e2-standard-4"]
  #   capacity_type   = "ON_DEMAND"
  #   use_name_prefix = false
  #   name            = "datafold-ng-small"
  #
  #   force_update_version = true
  #   update_config        = { "max_unavailable_percentage" : 50 }
  # }

  # To enable private access
  # deploy_private_access = true
  # allowed_principals    = local.vpn_allowed_principals
  # vpn_cidr              = local.vpn_cidr
}
