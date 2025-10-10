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
  #  Error 400: Invalid request: Only _custom machine instance_ type and _shared-core_
  # instance type allowed for PostgreSQL database.
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

variable "database_edition" {
  type        = string
  default     = null  # Auto determined by module or API
  description = "The edition of the database (ENTERPRISE or ENTERPRISE_PLUS). If null, automatically determined based on version."

  validation {
    condition     = var.database_edition == null ? true : contains(["ENTERPRISE", "ENTERPRISE_PLUS"], var.database_edition)
    error_message = "database_edition must be either ENTERPRISE or ENTERPRISE_PLUS."
  }
}

variable "common_tags" {
  type = map(string)
}
