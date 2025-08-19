output "lb_external_ip" {
  value = jsonencode([local.external_ip])
}

output "neg_name" {
  value = local.neg_name
}
