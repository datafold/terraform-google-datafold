#  ╻  ┏┓
#  ┃  ┣┻┓
#  ┗━╸┗━┛

variable "project_id" {
  type        = string
  description = "The project to deploy to."
}

variable "deployment_name" {
  type        = string
  description = "Name of the current deployment."
}

variable "azs" {
  type        = list(any)
  description = "Availability zones to deploy into"
}

variable "create_ssl_cert" {
  type    = bool
  default = false
}

variable "domain_name" {
  type        = string
  description = "Provide valid domain name (used to set host in GCP)"
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
}

variable "lb_layer_7_ddos_defence" {
  type        = bool
  default     = false
  description = "Flag to toggle layer 7 ddos defence"
}

variable "ssl_cert_name" {
  type        = string
  default     = ""
  description = "Provide valid SSL certificate name in GCP OR ssl_private_key_path and ssl_cert_path"
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

variable "deploy_neg_backend" {
  type        = bool
  default     = true
  description = "Set this to true to connect the backend service to the NEG that the GKE cluster will create"
}

variable "deploy_lb" {
  type        = bool
  default     = true
  description = "Allows a deploy with a not-yet-existing load balancer"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC network where the GKE cluster will be created"
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork where the GKE cluster will be deployed"
}
