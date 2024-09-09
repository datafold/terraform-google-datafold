locals {
  lb_app_rules = [
    {
      action         = "deny(403)"
      priority       = 2147483647
      description    = "Default deny rule"
      match_type     = "src_ip_ranges"
      versioned_expr = "SRC_IPS_V1"
      src_ip_ranges  = ["*"]
      expr           = "" # Placeholder
    },
    {
      action         = "allow"
      priority       = 1000
      description    = "Allow access for IPs in whitelisted_ingress_cidrs"
      match_type     = "src_ip_ranges"
      versioned_expr = "SRC_IPS_V1"
      src_ip_ranges  = local.lb_whitelisted_ingress_cidrs
      expr           = "" # Placeholder
    },
    {
      action         = "allow"
      priority       = 1001
      description    = "Allow access for Github web hooks"
      match_type     = "src_ip_ranges"
      versioned_expr = "SRC_IPS_V1"
      src_ip_ranges  = local.github_cidrs
      expr           = "" # Placeholder
    },
  ]
}
