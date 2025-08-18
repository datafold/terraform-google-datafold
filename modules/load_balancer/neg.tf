locals {
  neg_name = resource.random_id.neg_name.hex
}

resource "random_id" "neg_name" {
  prefix      = "datafold-"
  byte_length = 16
}

resource "google_compute_network_endpoint_group" "nginx" {
  count = var.deploy_lb && var.deploy_neg_backend ? 1 : 0

  name         = local.neg_name
  network      = var.vpc_id
  subnetwork   = var.subnetwork
  default_port = "80"
  zone         = var.azs[0]
  description  = local.neg_name
}
