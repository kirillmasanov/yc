output "external_ipv4_address" {
  value = yandex_vpc_address.alb-external-ip.external_ipv4_address[0].address
}

# output "cert_id" {
#   value = yandex_cm_certificate.dns-cert.id
# }