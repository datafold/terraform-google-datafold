data "google_container_engine_versions" "cluster" {
  project        = var.project_id
  provider       = google-beta
  location       = var.azs[0]
  version_prefix = "${var.k8s_cluster_version}-"
}

data "google_container_engine_versions" "nodes" {
  project        = var.project_id
  provider       = google-beta
  location       = var.azs[0]
  version_prefix = "${var.k8s_cluster_version}-"
}

resource "google_container_cluster" "default" {
  provider = google-beta

  name = "${var.deployment_name}-cluster"

  project            = var.project_id
  network            = var.vpc_id
  subnetwork         = var.subnetwork
  min_master_version = data.google_container_engine_versions.cluster.latest_master_version

  networking_mode = "VPC_NATIVE"

  enable_intranode_visibility = true
  enable_shielded_nodes       = true

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.vpc_master_cidr_block
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.k8s_authorized_networks
      content {
        cidr_block = cidr_blocks.key
        display_name = cidr_blocks.value
      }
    }
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.vpc_secondary_ranges_name_pods
    services_ipv4_cidr_block = var.vpc_secondary_ranges_name_services
  }

  release_channel {
    channel = var.k8s_node_auto_upgrade ? "STABLE" : "UNSPECIFIED"
  }

  node_config {
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  lifecycle {
    ignore_changes = [
      node_config,
    ]
  }

  cluster_autoscaling {
    enabled = false
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
  }
}

resource "google_container_node_pool" "default" {
  name       = "${var.deployment_name}default-pool"
  cluster    = google_container_cluster.default.id
  node_count = var.initial_node_count
  version    = var.k8s_node_version == "" ? null : data.google_container_engine_versions.nodes.latest_master_version

  node_config {
    image_type      = "COS_CONTAINERD"
    machine_type    = var.machine_type
    disk_size_gb    = var.disk_size_gb
    disk_type       = var.disk_type
    service_account = resource.google_service_account.gke_service_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    # Define the labels for the nodes
    labels = {
      default-node-pool = true
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 2
    location_policy = "ANY"
  }

  management {
    auto_upgrade = var.k8s_node_auto_upgrade
    auto_repair  = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [
      location,
    ]
    create_before_destroy = true
  }
}

resource "google_container_node_pool" "ch_node_pool" {
  count      = var.enable_ch_node_pool ? 1 : 0
  name       = "${var.deployment_name}ch-node-pool"
  cluster    = google_container_cluster.default.id
  node_count = var.initial_node_count
  version    = var.k8s_node_version == "" ? null : data.google_container_engine_versions.nodes.latest_master_version

  node_config {
    image_type      = "COS_CONTAINERD"
    machine_type    = var.ch_machine_type
    disk_size_gb    = var.disk_size_gb
    disk_type       = var.disk_type
    service_account = resource.google_service_account.gke_service_account.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }
    # Define the labels for the nodes
    labels = {
      default-node-pool = false
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }
    taint {
      key    = "clickhouse"
      value  = "reserved"
      effect = "NO_SCHEDULE"
    }
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 1
    location_policy = "ANY"
  }

  management {
    auto_upgrade = var.k8s_node_auto_upgrade
    auto_repair  = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [
      location,
    ]
    create_before_destroy = true
  }
}
