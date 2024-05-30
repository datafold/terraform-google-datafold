# ╻┏ ┏━┓┏━┓
# ┣┻┓┣━┫┗━┓
# ╹ ╹┗━┛┗━┛

variable "project_id" {
  type        = string
  description = "The project to deploy to."
}

variable "azs" {
  type        = list(any)
  description = "Availability zones to deploy into"
}

variable "k8s_cluster_version" {
  type        = string
  default     = "1.27"
  description = "The version of Kubernetes to use for the GKE cluster. The patch/GKE specific version will be found automatically."
}

variable "deployment_name" {
  type        = string
  description = "The name of the GKE cluster - often customer related"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC network where the GKE cluster will be created"
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork where the GKE cluster will be deployed"
}

variable "vpc_master_cidr_block" {
  type        = string
  default     = "192.168.0.0/28"
  description = "cidr block for k8s master, must be a /28 block."
}

variable "vpc_secondary_ranges_name_pods" {
  type        = string
  default     = "/17"
  description = "The name of the secondary range to be used for pods"
}

variable "vpc_secondary_ranges_name_services" {
  type        = string
  default     = "/22"
  description = "The name of the secondary range to be used for services"
}

variable "initial_node_count" {
  type        = number
  default     = 1
  description = "The initial number of nodes for each node pool in the GKE cluster"
}

variable "machine_type" {
  type        = string
  default     = "e2-highmem-8"
  description = "The machine type for the GKE cluster nodes"
}

variable "disk_size_gb" {
  type        = number
  default     = 40
  description = "The disk size in GB for the GKE cluster nodes"
}

variable "disk_type" {
  type        = string
  default     = "pd-standard"
  description = "The disk type for the GKE cluster nodes"
}

variable "enable_app_node_pool" {
  description = "Whether to enable the app node pool"
  type        = bool
  default     = false
}

variable "enable_ch_node_pool" {
  description = "Whether to enable the ch node pool"
  type        = bool
  default     = false
}

variable "app_np_machine_type" {
  type        = string
  default     = "e2-highmem-16"
  description = "The machine type for the app GKE cluster nodes"
}

variable "ch_machine_type" {
  type        = string
  default     = "n2-standard-8"
  description = "The machine type for the ch GKE cluster nodes"
}