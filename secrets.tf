resource "random_password" "clickhouse_password" {
  length      = 16
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  special     = false
}

resource "random_password" "postgres_ro_password" {
  length  = 16
  special = false
}

resource "random_password" "redis_password" {
  length  = 12
  special = false
}
