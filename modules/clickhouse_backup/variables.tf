#  ┏━╸╻  ╻┏━╸╻┏ ╻ ╻┏━┓╻ ╻┏━┓┏━╸
#  ┃  ┃  ┃┃  ┣┻┓┣━┫┃ ┃┃ ┃┗━┓┣╸
#  ┗━╸┗━╸╹┗━╸╹ ╹╹ ╹┗━┛┗━┛┗━┛┗━╸

variable "provider_region" {
  type        = string
  description = "Region for deployment in GCP"
}

variable "project_id" {
  type        = string
  description = "The project to deploy to, if not set the default provider project is used."
}

variable "deployment_name" {
  type        = string
  description = "Name of the current deployment."
}

variable "clickhouse_gcs_bucket" {
  type        = string
  default     = "clickhouse-backups-abcguo23"
  description = "Bucket for clickhouse backups."
}

variable "clickhouse_get_backup_sa_from_secrets_yaml" {
  type        = bool
  description = "Flag to toggle getting clickhouse backup SA from secrets.yaml instead of creating new one"
  default     = false
}

variable "clickhouse_backup_sa_key" {
  type        = string
  description = "SA key from secrets"
  default     = ""
}

variable "legacy_naming" {
  type        = bool
  default     = true
  description = "Flag to toggle legacy behavior - like naming of resources"
}
