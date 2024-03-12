output "clickhouse_backup_sa" {
  value       = module.clickhouse_backup.clickhouse_backup_sa
  description = "Name of the clickhouse backup Service Account"
}

output "clickhouse_data_size" {
  value       = resource.google_compute_disk.clickhouse_data.size
  description = "Size in GB of the clickhouse data volume"
}

output "clickhouse_data_volume_id" {
  value       = resource.google_compute_disk.clickhouse_data.id
  description = "Volume ID of the clickhouse data PD volume"
}

output "clickhouse_gcs_bucket" {
  value       = module.clickhouse_backup.clickhouse_gcs_bucket
  description = "Name of the GCS bucket for the clickhouse backups"
}

output "clickhouse_logs_size" {
  value       = resource.google_compute_disk.clickhouse_logs.size
  description = "Size in GB of the clickhouse logs volume"
}

output "clickhouse_logs_volume_id" {
  value       = resource.google_compute_disk.clickhouse_logs.id
  description = "Volume ID of the clickhouse logs PD volume"
}

output "clickhouse_password" {
  value       = resource.random_password.clickhouse_password.result
  description = "Password to use for clickhouse"
}

output "cluster_name" {
  value       = module.gke.cluster_name
  description = "The name of the GKE cluster that was created"
}

output "domain_name" {
  value       = coalesce(var.host_override, var.domain_name)
  description = "The domain name on the HTTPS certificate"
}

output "db_instance_id" {
  value       = module.database.db_instance_id
  description = "The database instance ID"
}

output "deployment_name" {
  value       = var.deployment_name
  description = "The name of the deployment"
}

output "lb_external_ip" {
  value       = module.load_balancer.lb_external_ip
  description = "The load balancer IP when it was provisioned."
}

output "neg_name" {
  value       = module.load_balancer.neg_name
  description = "The name of the Network Endpoint Group where pods need to be registered from kubernetes."
}

output "postgres_username" {
  value       = module.database.postgres_username
  description = "The postgres username"
}

output "postgres_password" {
  value       = module.database.postgres_password
  description = "The postgres password"
}

output "postgres_database_name" {
  value       = module.database.postgres_database_name
  description = "The name of the postgres database"
}

output "postgres_host" {
  value       = module.database.postgres_host
  description = "The hostname of the postgres database"
}

output "postgres_port" {
  value       = module.database.postgres_port
  description = "The port of the postgres database"
}

output "redis_password" {
  value       = resource.random_password.redis_password.result
  description = "The Redis password"
}

output "vpc_id" {
  value       = local.vpc_id
  description = "The ID of the Google VPC the cluster runs in."
}

output "vpc_cidr" {
  value       = var.vpc_cidr
  description = "The VPC CIDR range"
}

output "vpc_subnetwork" {
  value       = local.vpc_subnetwork
  description = "The subnet in which the cluster is created"
}

output "cloud_provider" {
  value       = "gcp"
  description = "The cloud provider creating all the resources"
}

output "redis_data_size" {
  value       = resource.google_compute_disk.redis_data.size
  description = "The size in GB of the redis data volume"
}

output "redis_data_volume_id" {
  value       = resource.google_compute_disk.redis_data.id
  description = "The volume ID of the Redis PD data volume"
}
