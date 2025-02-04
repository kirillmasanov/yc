resource "yandex_dns_zone" "dns-zone" {
  name   = "dz-zone"
  zone   = "${var.dns}."
  public = true
}

resource "yandex_vpc_address" "alb-external-ip" {
  name = "alb-external-ip"

  external_ipv4_address {
    zone_id = var.zone
  }
}

resource "yandex_dns_recordset" "dns_record" {
  zone_id = yandex_dns_zone.dns-zone.id
  name    = "${var.dns}."
  type    = "A"
  ttl     = 60
  data    = [yandex_vpc_address.alb-external-ip.external_ipv4_address[0].address]
}

# resource "yandex_cm_certificate" "dns-cert" {
#   name    = "dns-cert"
#   domains = [var.dns]

#   managed {
#     challenge_type  = "DNS_CNAME"
#     challenge_count = 1
#   }
# }

# resource "yandex_dns_recordset" "dns-cert-record" {
#   count   = yandex_cm_certificate.dns-cert.managed[0].challenge_count
#   zone_id = yandex_dns_zone.dns-zone.id
#   name    = yandex_cm_certificate.dns-cert.challenges[count.index].dns_name
#   type    = yandex_cm_certificate.dns-cert.challenges[count.index].dns_type
#   data    = [yandex_cm_certificate.dns-cert.challenges[count.index].dns_value]
#   ttl     = 60
# }