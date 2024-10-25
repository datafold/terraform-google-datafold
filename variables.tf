#  ╻ ╻┏━┓┏━┓╻┏━┓┏┓ ╻  ┏━╸┏━┓
#  ┃┏┛┣━┫┣┳┛┃┣━┫┣┻┓┃  ┣╸ ┗━┓
#  ┗┛ ╹ ╹╹┗╸╹╹ ╹┗━┛┗━╸┗━╸┗━┛

#  ┏━╸┏━┓┏┳┓┏┳┓┏━┓┏┓╻
#  ┃  ┃ ┃┃┃┃┃┃┃┃ ┃┃┗┫
#  ┗━╸┗━┛╹ ╹╹ ╹┗━┛╹ ╹

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to any resource"
}

variable "environment" {
  type        = string
  description = "Global environment tag to apply on all datadog logs, metrics, etc."
}

variable "deployment_name" {
  type        = string
  description = "Name of the current deployment."
}

variable "project_id" {
  type        = string
  description = "The project to deploy to, if not set the default provider project is used."
}

variable "add_onprem_support_group" {
  type        = bool
  default     = true
  description = "Flag to add onprem support group for datafold-onprem-support@datafold.com"
}

variable "legacy_naming" {
  type        = bool
  default     = true
  description = "Flag to toggle legacy behavior - like naming of resources"
}

variable "restricted_viewer_role" {
  type        = bool
  default     = false
  description = "Flag to stop certain IAM related resources from being updated/changed"
}

variable "restricted_roles" {
  type        = bool
  default     = false
  description = "Flag to stop certain IAM related resources from being updated/changed"
}

variable "redis_data_size" {
  type        = number
  default     = 10
  description = "Redis volume size"
}

#  ┏━┓┏━┓┏━┓╻ ╻╻╺┳┓┏━╸┏━┓
#  ┣━┛┣┳┛┃ ┃┃┏┛┃ ┃┃┣╸ ┣┳┛
#  ╹  ╹┗╸┗━┛┗┛ ╹╺┻┛┗━╸╹┗╸

variable "provider_region" {
  type        = string
  description = "Region for deployment in GCP"
}

variable "provider_azs" {
  type        = list(string)
  description = "Provider AZs list, if empty we get AZs dynamically"
}

#  ╻  ┏┓
#  ┃  ┣┻┓
#  ┗━╸┗━┛

# Provide only ssl_cert_name or (ssl_cert_path and ssl_private_key_path)

variable "create_ssl_cert" {
  type        = bool
  default     = false
  description = "True to create the SSL certificate, false if not"
}

variable "ssl_cert_name" {
  type        = string
  default     = ""
  description = "Provide valid SSL certificate name in GCP OR ssl_private_key_path and ssl_cert_path"
}

variable "domain_name" {
  type        = string
  description = "Provide valid domain name (used to set host in GCP)"
}

variable "host_override" {
  type        = string
  default     = ""
  description = "A valid domain name if they provision their own DNS / routing"
}

variable "ssl_cert_path" {
  type        = string
  default     = ""
  description = "SSL certificate path"
}

variable "ssl_private_key_path" {
  type        = string
  default     = ""
  description = "Private SSL key path"
}


variable "lb_app_rules" {
  type = list(object({
    action         = string
    priority       = number
    description    = string
    match_type     = string       # can be either "src_ip_ranges" or "expr"
    versioned_expr = string       # optional, only used if match_type is "src_ip_ranges"
    src_ip_ranges  = list(string) # optional, only used if match_type is "src_ip_ranges"
    expr           = string       # optional, only used if match_type is "expr"
  }))
  description = "Extra rules to apply to the application load balancer for additional filtering"
}

variable "lb_layer_7_ddos_defence" {
  type        = bool
  default     = false
  description = "Flag to toggle layer 7 ddos defence"
}

variable "deploy_neg_backend" {
  type        = bool
  default     = true
  description = "Set this to true to connect the backend service to the NEG that the GKE cluster will create"
}

#  ╻ ╻┏━┓┏━╸
#  ┃┏┛┣━┛┃
#  ┗┛ ╹  ┗━╸

variable "vpc_id" {
  type        = string
  default     = ""
  description = "Provide ID of existing VPC if you want to omit creation of new one"
}

variable "vpc_cidr" {
  type        = string
  description = "Network CIDR for VPC"
  default     = "10.0.0.0/16"
  validation {
    condition     = can(regex("^\\d{1,3}(\\.\\d{1,3}){3}/\\d{1,2}$", var.vpc_cidr))
    error_message = "Network CIDR must be a valid cidr."
  }
}

variable "vpc_secondary_cidr_pods" {
  type        = string
  default     = "/17"
  description = "Network CIDR for VPC secundary subnet 1"
  validation {
    condition     = can(regex("^/\\d{1,2}$", var.vpc_secondary_cidr_pods))
    error_message = "Network CIDR must be a valid cidr."
  }
}

variable "vpc_secondary_cidr_services" {
  type        = string
  default     = "/17"
  description = "Network CIDR for VPC secundary subnet 2"
  validation {
    condition     = can(regex("^/\\d{1,2}$", var.vpc_secondary_cidr_services))
    error_message = "Network CIDR must be a valid cidr."
  }
}

variable "whitelisted_ingress_cidrs" {
  type        = list(string)
  description = "List of CIDRs that can access the HTTP/HTTPS"
  validation {
    condition = alltrue([
      for ip in var.whitelisted_ingress_cidrs :
      can(regex("^\\d{1,3}(\\.\\d{1,3}){3}/\\d{1,2}$", ip))
    ])
    error_message = "Network CIDR must be a valid cidr."
  }
}

variable "whitelist_all_ingress_cidrs_lb" {
  type        = bool
  default     = false
  description = "Normally we filter on the load balancer, but some customers want to filter at the SG/Firewall. This flag will whitelist 0.0.0.0/0 on the load balancer."
}

variable "whitelisted_egress_cidrs" {
  type        = list(string)
  description = "List of Internet addresses to which the application has access"
  validation {
    condition = alltrue([
      for ip in var.whitelisted_egress_cidrs :
      can(regex("^\\d{1,3}(\\.\\d{1,3}){3}/\\d{1,2}$", ip))
    ])
    error_message = "Network CIDR must be a valid cidr."
  }
}

variable "deploy_vpc_flow_logs" {
  type        = bool
  default     = false
  description = "Flag weither or not to deploy vpc flow logs"
}

variable "vpc_flow_logs_interval" {
  type        = string
  default     = "INTERVAL_5_SEC"
  description = "Interval for vpc flow logs"
}

variable "vpc_flow_logs_sampling" {
  type        = string
  default     = "0.5"
  description = "Sampling for vpc flow logs"
}

variable "cloud_router_bgp" {
  type = object(
    {
      asn = string
      # advertise_mode = optional(string, "DEFAULT")
      # advertised_groups = optional(list(string))
      # advertised_ip_ranges = optional(
      #   list(
      #     object({
      #       range = string
      #       description = optional(string)
      #     })
      #   ),
      #   []
      # )
      keepalive_interval = optional(number)
    }
  )
  default     = null
  description = "Flag to toggle cloud router bgp"
}

variable "cloud_router_nats" {
  description = "NATs to deploy on this router."
  type = list(object({
    name                                = string
    nat_ip_allocate_option              = optional(string)
    source_subnetwork_ip_ranges_to_nat  = optional(string)
    nat_ips                             = optional(list(string), [])
    min_ports_per_vm                    = optional(number)
    max_ports_per_vm                    = optional(number)
    udp_idle_timeout_sec                = optional(number)
    icmp_idle_timeout_sec               = optional(number)
    tcp_established_idle_timeout_sec    = optional(number)
    tcp_transitory_idle_timeout_sec     = optional(number)
    tcp_time_wait_timeout_sec           = optional(number)
    enable_endpoint_independent_mapping = optional(bool)
    enable_dynamic_port_allocation      = optional(bool)

    log_config = optional(object({
      enable = optional(bool, true)
      filter = optional(string, "ALL")
    }), {})

    subnetworks = optional(list(object({
      name                     = string
      source_ip_ranges_to_nat  = list(string)
      secondary_ip_range_names = optional(list(string))
    })), [])

  }))
  default = []
}

#  ┏┳┓╻┏━╸
#  ┃┃┃┃┃╺┓
#  ╹ ╹╹┗━┛

variable "mig_disk_type" {
  type        = string
  default     = "pd-balanced"
  description = <<-EOT
    https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance_template#disk_type
EOT
  validation {
    condition     = contains(["pd-ssd", "local-ssd", "pd-balanced", "pd-standard"], var.mig_disk_type)
    error_message = "Wrong disk type for MIG."
  }
}

variable "clickhouse_data_disk_size" {
  type        = number
  default     = 40
  description = "Data volume size clickhouse"
}

#  ╺┳┓┏━┓╺┳╸┏━┓┏┓ ┏━┓┏━┓┏━╸
#   ┃┃┣━┫ ┃ ┣━┫┣┻┓┣━┫┗━┓┣╸
#  ╺┻┛╹ ╹ ╹ ╹ ╹┗━┛╹ ╹┗━┛┗━╸

variable "postgres_username" {
  type        = string
  default     = "datafold"
  description = "The username to use for the postgres CloudSQL database"
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
  type        = number
  default     = 20
  description = "The amount of allocated storage for the postgres database"
}

variable "db_deletion_protection" {
  type        = bool
  default     = true
  description = "A flag that sets delete protection (applied in terraform only, not on the cloud)."
}

variable "database_name" {
  type        = string
  default     = "datafold"
  description = "The name of the database"
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

#  ┏━╸╻  ╻┏━╸╻┏ ╻ ╻┏━┓╻ ╻┏━┓┏━╸
#  ┃  ┃  ┃┃  ┣┻┓┣━┫┃ ┃┃ ┃┗━┓┣╸
#  ┗━╸┗━╸╹┗━╸╹ ╹╹ ╹┗━┛┗━┛┗━┛┗━╸

variable "clickhouse_username" {
  type        = string
  default     = "clickhouse"
  description = "Username for clickhouse."
}

variable "clickhouse_db" {
  type        = string
  default     = "clickhouse"
  description = "Db for clickhouse."
}

variable "clickhouse_gcs_bucket" {
  type        = string
  default     = "clickhouse-backups-abcguo23"
  description = "GCS Bucket for clickhouse backups."
}

variable "gcs_path" {
  type        = string
  description = "Path in the GCS bucket to the backups"
  default     = "backups"
}

variable "remote_storage" {
  type        = string
  description = "Type of remote storage for clickhouse backups."
  default     = "gcs"
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

# ┏━╸╻╺┳╸╻ ╻╻ ╻┏┓
# ┃╺┓┃ ┃ ┣━┫┃ ┃┣┻┓
# ┗━┛╹ ╹ ╹ ╹┗━┛┗━┛

variable "github_endpoint" {
  type        = string
  default     = ""
  description = "URL of Github endpoint to connect to. Useful for Github Enterprise."
}

# ┏━╸╻╺┳╸╻  ┏━┓┏┓
# ┃╺┓┃ ┃ ┃  ┣━┫┣┻┓
# ┗━┛╹ ╹ ┗━╸╹ ╹┗━┛

variable "gitlab_endpoint" {
  type        = string
  default     = ""
  description = "URL of Gitlab endpoint to connect to. Useful for GItlab Enterprise."
}

# ╻┏┓╻╺┳╸┏━╸┏━┓┏━╸┏━┓┏┳┓
# ┃┃┗┫ ┃ ┣╸ ┣┳┛┃  ┃ ┃┃┃┃
# ╹╹ ╹ ╹ ┗━╸╹┗╸┗━╸┗━┛╹ ╹

variable "datafold_intercom_app_id" {
  type        = string
  default     = ""
  description = "The app id for the intercom. A value other than \"\" will enable this feature. Only used if the customer doesn't use slack."
}

# ┏━╸╻┏ ┏━╸
# ┃╺┓┣┻┓┣╸
# ┗━┛╹ ╹┗━╸

variable "default_node_disk_size" {
  type        = number
  default     = 40
  description = "Root disk size for a cluster node"
}

variable "vpc_master_cidr_block" {
  type        = string
  default     = "192.168.0.0/28"
  description = "cidr block for k8s master, must be a /28 block."
}

variable "machine_type" {
  type        = string
  default     = "e2-highmem-8"
  description = "The machine type for the GKE cluster nodes"
}

variable "enable_ch_node_pool" {
  description = "Whether to enable the ch node pool"
  type        = bool
  default     = false
}

variable "custom_node_pools" {
  type = list(object({
    name = string
    enabled = bool
    initial_node_count = number
    machine_type = string
    disk_size_gb = number
    disk_type = string
    spot = bool
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    min_node_count  = number
    max_node_count  = number
    max_surge       = number
    max_unavailable = number
    labels          = map(string)
  }))
  description = "Dynamic extra node pools"
  default = []
}

variable "ch_machine_type" {
  type        = string
  default     = "n2-standard-8"
  description = "The machine type for the ch GKE cluster nodes"
}

variable "k8s_authorized_networks" {
  type        = map(string)
  default     = {"0.0.0.0/0": "public"}
  description = "Map of CIDR blocks that are able to connect to the K8S control plane"
}

variable "k8s_cluster_version" {
  type        = string
  default     = "1.28.11"
  description = "The version of Kubernetes to use for the GKE cluster. The patch/GKE specific version will be found automatically."
}

variable "k8s_node_auto_upgrade" {
  type        = bool
  default     = false
  description = "Whether to enable auto-upgrade for the GKE cluster nodes"
}

variable "k8s_node_version" {
  type        = string
  default     = "1.28.11"
  description = "The version of the nodes"
}
