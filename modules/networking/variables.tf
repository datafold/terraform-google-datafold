#  ╻ ╻┏━┓┏━╸
#  ┃┏┛┣━┛┃
#  ┗┛ ╹  ┗━╸

variable "provider_region" {
  type        = string
  description = "Region for deployment in GCP"
}

variable "provider_azs" {
  type        = list(string)
  description = "Provider AZs list, if empty we get AZs dynamically"
}

variable "project_id" {
  type        = string
  description = "The project to deploy to."
}

variable "deployment_name" {
  type        = string
  description = "Name of the current deployment."
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "Provide ID of existing VPC if you want to omit creation of new one"
}

variable "vpc_cidr" {
  type        = string
  description = "Network CIDR for VPC"
  validation {
    condition     = can(regex("^\\d{1,3}(\\.\\d{1,3}){3}/\\d{1,2}$", var.vpc_cidr))
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
