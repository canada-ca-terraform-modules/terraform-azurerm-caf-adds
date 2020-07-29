output "dc1" {
  value = var.deploy ? module.dc1 : null
}

output "dc2" {
  value = var.deploy ? module.dc2 : null
}

output "domain" {
  value = var.deploy ? var.ad_domain_name : null
}