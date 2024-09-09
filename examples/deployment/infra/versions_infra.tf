terraform {
  required_providers {
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.5"
    }
  }
}

locals {
  gcp_terraform_version = "1.3.0"
}
