terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.27.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.2.1"
    }
  }
}
