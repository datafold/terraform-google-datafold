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

variable "enable_ch_node_pool" {
  description = "Whether to enable the ch node pool"
  type        = bool
  default     = false
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
  }))
  description = "Dynamic extra node pools"
  default     = []
}
