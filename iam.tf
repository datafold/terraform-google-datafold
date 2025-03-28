#  ┏┳┓╻┏━╸
#  ┃┃┃┃┃╺┓
#  ╹ ╹╹┗━┛

locals {
  viewer_role = var.restricted_viewer_role ? "roles/viewer" : "roles/compute.viewer"
  project_roles = var.restricted_roles ? [] : [
    "${var.project_id}=>${local.viewer_role}",
  ]
}

# ╺┳┓┏━┓╺┳╸┏━┓┏━╸┏━┓╻  ╺┳┓   ┏━┓╻ ╻┏━┓┏━┓┏━┓┏━┓╺┳╸
#  ┃┃┣━┫ ┃ ┣━┫┣╸ ┃ ┃┃   ┃┃   ┗━┓┃ ┃┣━┛┣━┛┃ ┃┣┳┛ ┃
# ╺┻┛╹ ╹ ╹ ╹ ╹╹  ┗━┛┗━╸╺┻┛   ┗━┛┗━┛╹  ╹  ┗━┛╹┗╸ ╹

module "project-iam-bindings" {
  count    = var.add_onprem_support_group ? 1 : 0
  source   = "terraform-google-modules/iam/google//modules/projects_iam"
  projects = [var.project_id]
  mode     = "additive"

  bindings = {
    "roles/compute.instanceAdmin.v1" = [
      "group:datafold-onprem-support@datafold.com"
    ]
    "roles/viewer" = [
      "group:datafold-onprem-support@datafold.com"
    ]
    "roles/iap.tunnelResourceAccessor" = [
      "group:datafold-onprem-support@datafold.com"
    ]
#    "roles/container.admin" = [
#      "group:datafold-onprem-support@datafold.com"
#    ]
    "roles/container.clusterAdmin" = [
      "group:datafold-onprem-support@datafold.com"
    ]
  }
}
