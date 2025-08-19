locals {
  allow_scr_ip_ranges = var.whitelist_all_ingress_cidrs_lb ? ["*"] : var.whitelisted_ingress_cidrs
  project_id          = var.project_id
  azs                 = var.azs
}

resource "google_compute_ssl_policy" "lb_app" {
  project         = var.project_id
  name            = "${var.deployment_name}-app"
  profile         = "RESTRICTED"
  min_tls_version = "TLS_1_2"
}

resource "google_compute_security_policy" "lb_app" {
  project = var.project_id
  name    = "${var.deployment_name}-app"

  # Not very readable, but needed to support multiple types of matches: 'src_ip_ranges' and 'expr'.
  # The first 'dynamic "match"' block is used when the 'match_type' is 'src_ip_ranges'.
  # In this case, it sets 'versioned_expr' to 'SRC_IPS_V1' and 'src_ip_ranges' to the value from the 'lb_app_rules' list.
  # The second 'dynamic "match"' block is used when the 'match_type' is 'expr'.
  # In this case, it sets the 'expression' field to the 'expr' value from the 'lb_app_rules' list.
  dynamic "rule" {
    for_each = var.lb_app_rules
    content {
      action      = rule.value.action
      priority    = rule.value.priority
      description = rule.value.description
      dynamic "match" {
        for_each = rule.value.match_type == "src_ip_ranges" ? [rule.value.match_type] : []
        content {
          versioned_expr = match.value == "src_ip_ranges" ? "SRC_IPS_V1" : null
          config {
            src_ip_ranges = match.value == "src_ip_ranges" ? rule.value.src_ip_ranges : null
          }
        }
      }
      dynamic "match" {
        for_each = rule.value.match_type == "expr" ? [rule.value.match_type] : []
        content {
          expr {
            expression = rule.value.expr
          }
        }
      }
    }
  }

  dynamic "adaptive_protection_config" {
    for_each = var.lb_layer_7_ddos_defence ? [true] : []
    content {
      layer_7_ddos_defense_config {
        enable = true
      }
    }
  }
}

resource "google_compute_managed_ssl_certificate" "lb_app" {
  count = var.create_ssl_cert ? 1 : 0

  name = var.ssl_cert_name

  managed {
    domains = [var.domain_name]
  }
}

data "google_compute_ssl_certificate" "lb_app" {
  count   = var.deploy_lb && var.ssl_cert_name != "" ? 1 : 0
  project = var.project_id
  name    = var.ssl_cert_name

  depends_on = [
    google_compute_managed_ssl_certificate.lb_app,
  ]
}

# https://registry.terraform.io/modules/GoogleCloudPlatform/lb-http/google/latest
module "lb_app" {
  source  = "GoogleCloudPlatform/lb-http/google"
  version = "12.1.4"

  count             = var.deploy_lb ? 1 : 0

  project           = var.project_id
  name              = "${var.deployment_name}-app"
  target_tags       = ["app"]
  firewall_networks = []

  # We enable SSL only if provided ssl_certificates or (certificate and private_key)
  ssl                    = var.ssl_cert_name != "" || (var.ssl_cert_path != "" && var.ssl_private_key_path != "")
  https_redirect         = var.ssl_cert_name != "" || (var.ssl_cert_path != "" && var.ssl_private_key_path != "")
  create_ssl_certificate = var.ssl_cert_name == ""
  # Using already imported SSL cert
  ssl_certificates       = var.ssl_cert_name != "" ? [one(data.google_compute_ssl_certificate.lb_app[*].self_link)] : []

  # OR Create new SSL cert
  certificate = var.ssl_cert_path != "" ? file(var.ssl_cert_path) : null
  private_key = var.ssl_private_key_path != "" ? file(var.ssl_private_key_path) : null

  security_policy = google_compute_security_policy.lb_app.id
  ssl_policy      = google_compute_ssl_policy.lb_app.self_link

  backends = {
    default = {
      description             = null
      protocol                = "HTTP"
      port                    = 80
      port_name               = "http"
      timeout_sec             = 300
      enable_cdn              = false
      custom_request_headers  = null
      custom_response_headers = null
      security_policy         = null

      connection_draining_timeout_sec = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null

      health_check = {
        check_interval_sec  = null
        timeout_sec         = null
        healthy_threshold   = null
        unhealthy_threshold = null
        request_path        = "/nginx-health"
        port                = 80
        host                = null
        logging             = null
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = var.deploy_neg_backend ? [{
        group           = one(resource.google_compute_network_endpoint_group.nginx[*].id)
        balancing_mode  = "RATE"
        max_rate        = 1000
        capacity_scaler = 1.0
      }] : []

      iap_config = {
        enable               = false
        oauth2_client_id     = null
        oauth2_client_secret = null
      }
    }
  }

  depends_on = [
    resource.google_compute_network_endpoint_group.nginx,
  ]
}

locals {
  external_ip = var.deploy_lb ? module.lb_app[0].external_ip : "255.255.255.255"
}
