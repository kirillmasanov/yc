output "network_id" {
  value = yandex_vpc_network.default.id
}

output "subnet_id" {
  value = {
    for k, v in yandex_vpc_subnet.default : k => v.id
  }
}

output "subnet_cidr" {
  value = {
    for k, v in yandex_vpc_subnet.default : k => v.v4_cidr_blocks
  }
}

output "vpc_subnet_default" {
  value = {
    for k, v in yandex_vpc_subnet.default : k => {
      name = v.name
      zone = v.zone
      id   = v.id
    }
  }
}