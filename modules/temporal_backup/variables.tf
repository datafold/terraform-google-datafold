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

variable "temporal_gcs_bucket" {
  type        = string
  default     = "temporal-pg-backups"
  description = "Suffix for the Temporal PostgreSQL backup GCS bucket name."
}

variable "backup_lifecycle_expiration_days" {
  type        = number
  default     = 7
  description = "Number of days after which Temporal PostgreSQL backup objects will expire and be deleted."
}

variable "temporal_postgres_namespace" {
  type        = string
  default     = "temporal"
  description = "Kubernetes namespace where the Temporal PostgreSQL CRD (and postgres-pod service account) is deployed."
}
