locals {
  environment     = "prod"
  project_id      = "acme-datafold-project"
  customer_name   = "acme"
  deployment_name = "acme-datafold"
  provider_region = "us-central1"
  provider_azs    = ["us-central1-a"]
  kms_profile     = "target_account_profile"
  # Create this symmetric encryption key in advance (manually)
  # It is used for encrypting / decrypting the secrets files.
  kms_key         = "arn:aws:kms:us-west-2:1234567890:alias/acme-datafold"

  # Common tags to be assigned to all resources
  common_tags = {
    Terraform   = true
    Environment = local.environment
  }
  lb_whitelisted_ingress_cidrs = ["0.0.0.0/0"]
  proxy_ip = "1.2.3.4/32"
  authorized_networks = {
    "${local.proxy_ip}" : "k8s-proxy",
  }

  # GitHub CIDRs for egress whitelist
  github_cidrs = [
    "140.82.112.0/20",
    "185.199.108.0/22",
    "192.30.252.0/22"
  ]

  # Kubernetes version
  k8s_version = "1.32"
}
