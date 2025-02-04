output "alb_info" {
  value = module.alb-ingress.alb_info
}

output "db_hostname" {
  value = module.mdb.db_hostname
}
