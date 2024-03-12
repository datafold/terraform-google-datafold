output "db_instance_id" {
  value = one(module.db[*].instance_name)
}

output "postgres_username" {
  value = var.postgres_username
}

output "postgres_password" {
  value = one(module.db[*].generated_user_password)
}

output "postgres_database_name" {
  value = var.database_name
}

output "postgres_host" {
  value = one(module.db[*].private_ip_address) == null ? "not_set" : one(module.db[*].private_ip_address)
}

output "postgres_port" {
  value = 5432
}
