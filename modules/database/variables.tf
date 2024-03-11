#  ╺┳┓┏━┓╺┳╸┏━┓┏┓ ┏━┓┏━┓┏━╸
#   ┃┃┣━┫ ┃ ┣━┫┣┻┓┣━┫┗━┓┣╸
#  ╺┻┛╹ ╹ ╹ ╹ ╹┗━┛╹ ╹┗━┛┗━╸

variable "provider_region" {
  type        = string
  description = "Region for deployment in GCP"
}

variable "project_id" {
  type        = string
  description = "The project to deploy to."
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "Provide ID of existing VPC if you want to omit creation of new one"
}

variable "azs" {
  type        = list(any)
  description = "Availability zones to deploy into"
}

variable "private_network" {
  type        = string
  description = "Private network to use"
}

variable "deployment_name" {
  type        = string
  description = "Name of the current deployment."
}

variable "postgres_username" {
  type    = string
  default = "datafold"
}

variable "postgres_instance" {
  type = string
  # https://cloud.google.com/sql/docs/mysql/instance-settings
  #  Error 400: Invalid request: Only custom machine instance type and shared-core
  # instance type allowed for PostgreSQL database., invalid
  default     = "db-custom-2-7680"
  description = <<-EOT
    GCP instance type for PostgreSQL database.
    Available instance groups: .
    Available instance classes: .
EOT
}

variable "postgres_allocated_storage" {
  type    = number
  default = 20
}

variable "db_deletion_protection" {
  type    = bool
  default = true
}

variable "database_name" {
  type    = string
  default = "datafold"
}

variable "postgres_ro_username" {
  type        = string
  default     = "datafold_ro"
  description = "Postgres read-only user name"
}

variable "database_version" {
  type        = string
  default     = "POSTGRES_15"
  description = "Version of the database"
}

variable "common_tags" {
  type = map(string)
}
