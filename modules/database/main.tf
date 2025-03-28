# https://registry.terraform.io/modules/GoogleCloudPlatform/sql-db/google/latest/submodules/private_service_access
module "db_private_service_access" {
  source      = "GoogleCloudPlatform/sql-db/google//modules/private_service_access"
  version     = "25.2"
  project_id  = var.project_id
  vpc_network = var.vpc_id
}

# https://registry.terraform.io/modules/GoogleCloudPlatform/sql-db/google/latest/submodules/postgresql
module "db" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "~> 25.2"

  project_id           = var.project_id
  name                 = var.deployment_name
  random_instance_name = true
  region               = var.provider_region
  zone                 = var.azs[0]

  database_version = var.database_version
  db_name          = var.database_name
  tier             = var.postgres_instance
  disk_size        = var.postgres_allocated_storage
  user_name        = var.postgres_username

  user_labels         = var.common_tags
  deletion_protection = var.db_deletion_protection

  ip_configuration = {
    require_ssl = false

    // Private
    ipv4_enabled        = false
    private_network     = var.private_network
    authorized_networks = []
    allocated_ip_range  = null
  }

  insights_config = {
    query_insights_enabled  = true
    query_plans_per_minute  = 5
    query_string_length     = 1024
    record_application_tags = false
    record_client_address   = false
  }

  backup_configuration = {
    enabled                        = true
    start_time                     = "20:00"
    location                       = null
    point_in_time_recovery_enabled = false
    transaction_log_retention_days = null
    retained_backups               = 7
    retention_unit                 = "COUNT"
  }

  depends_on = [module.db_private_service_access]
}
