data "google_client_config" "provider" {}

locals {
  proxy_url = "socks5://localhost:1080"
}

provider "helm" {
  kubernetes {
    host  = data.google_container_cluster.cluster.endpoint
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
    )
    proxy_url = local.proxy_url
  }
}

provider "kubernetes" {
  host  = data.google_container_cluster.cluster.endpoint
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  )
  proxy_url = local.proxy_url
}
