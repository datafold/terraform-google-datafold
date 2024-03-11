output "lb_external_ip" {
  value = jsonencode([module.lb_app.external_ip])
}

output "neg_name" {
  value = local.neg_name
}
