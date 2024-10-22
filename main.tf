module "project_factory_project_services" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  version                     = "~> 14.4.0"
  project_id                  = var.project_id
  disable_dependent_services  = false
  disable_services_on_destroy = false
  activate_apis = [
    "iam.googleapis.com",               // Service accounts
    "logging.googleapis.com",           // Logging
    "sqladmin.googleapis.com",          // Database
    "networkmanagement.googleapis.com", // Networking
    "servicenetworking.googleapis.com", // Networking
    "storage.googleapis.com",           // Cloud Storage
    "cloudkms.googleapis.com",          // KMS
    "compute.googleapis.com",           // required for compute
    "secretmanager.googleapis.com"      // required for secrets
  ]
}

module "clickhouse_backup" {
  source = "./modules/clickhouse_backup"

  provider_region                            = var.provider_region
  deployment_name                            = var.deployment_name
  clickhouse_gcs_bucket                      = var.clickhouse_gcs_bucket
  clickhouse_backup_sa_key                   = var.clickhouse_backup_sa_key
  project_id                                 = var.project_id
  clickhouse_get_backup_sa_from_secrets_yaml = var.clickhouse_get_backup_sa_from_secrets_yaml
  legacy_naming                              = var.legacy_naming
}

module "networking" {
  source = "./modules/networking"

  provider_region                = var.provider_region
  provider_azs                   = var.provider_azs
  project_id                     = var.project_id
  deployment_name                = var.deployment_name
  vpc_id                         = var.vpc_id
  vpc_cidr                       = var.vpc_cidr
  whitelisted_ingress_cidrs      = var.whitelisted_ingress_cidrs
  whitelist_all_ingress_cidrs_lb = var.whitelist_all_ingress_cidrs_lb
  whitelisted_egress_cidrs       = var.whitelisted_egress_cidrs
  deploy_vpc_flow_logs           = var.deploy_vpc_flow_logs
  vpc_flow_logs_interval         = var.vpc_flow_logs_interval
  vpc_flow_logs_sampling         = var.vpc_flow_logs_sampling
  cloud_router_bgp               = var.cloud_router_bgp
  cloud_router_nats              = var.cloud_router_nats

  depends_on = [module.project_factory_project_services]
}

locals {
  vpc_id         = module.networking.vpc_id
  vpc_subnetwork = module.networking.vpc_subnetwork
  vpc_selflink   = module.networking.vpc_selflink
  azs            = module.networking.azs
}

module "database" {
  source = "./modules/database"

  provider_region            = var.provider_region
  project_id                 = var.project_id
  deployment_name            = var.deployment_name
  vpc_id                     = local.vpc_id
  azs                        = local.azs
  private_network            = local.vpc_selflink
  postgres_username          = var.postgres_username
  postgres_instance          = var.postgres_instance
  postgres_allocated_storage = var.postgres_allocated_storage
  db_deletion_protection     = var.db_deletion_protection
  database_name              = var.database_name
  postgres_ro_username       = var.postgres_ro_username
  database_version           = var.database_version
  common_tags                = var.common_tags

  depends_on = [module.project_factory_project_services]
}

module "gke" {
  source = "./modules/gke"

  project_id              = var.project_id
  deployment_name         = var.deployment_name
  vpc_id                  = local.vpc_id
  subnetwork              = local.vpc_subnetwork
  azs                     = local.azs
  disk_size_gb            = var.default_node_disk_size
  vpc_master_cidr_block   = var.vpc_master_cidr_block
  machine_type            = var.machine_type
  enable_ch_node_pool     = var.enable_ch_node_pool
  ch_machine_type         = var.ch_machine_type
  k8s_authorized_networks = var.k8s_authorized_networks
  k8s_cluster_version     = var.k8s_cluster_version
  k8s_node_version        = var.k8s_node_version
  k8s_node_auto_upgrade   = var.k8s_node_auto_upgrade
  custom_node_pools       = var.custom_node_pools
}

module "load_balancer" {
  source = "./modules/load_balancer"

  project_id                     = var.project_id
  deployment_name                = var.deployment_name
  whitelisted_ingress_cidrs      = var.whitelisted_ingress_cidrs
  whitelist_all_ingress_cidrs_lb = var.whitelist_all_ingress_cidrs_lb
  lb_app_rules                   = var.lb_app_rules
  lb_layer_7_ddos_defence        = var.lb_layer_7_ddos_defence
  create_ssl_cert                = var.create_ssl_cert
  ssl_cert_name                  = var.ssl_cert_name
  domain_name                    = var.domain_name
  ssl_cert_path                  = var.ssl_cert_path
  ssl_private_key_path           = var.ssl_private_key_path
  azs                            = local.azs
  vpc_id                         = local.vpc_id
  subnetwork                     = local.vpc_subnetwork
  deploy_neg_backend             = var.deploy_neg_backend

  depends_on = [
    module.project_factory_project_services,
    module.networking,
  ]
}

locals {
  lb_external_ip = module.load_balancer.lb_external_ip
}
