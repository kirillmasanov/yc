variable "folder_id" {
  description = "Folder ID"
  type        = string
}

variable "network_id" {
  description = "ID of the VPC network"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR-блоки подсетей"
  type        = map(list(string))
}

variable "cluster_id" {
  description = "Kubernetes cluster ID."
  type        = string
}

variable "subnet_id" {
  description = "ID of subnet"
  type        = map(string)
}

variable "external_ipv4_address" {
  description = "ALB external IP"
}

variable "dns" {
  description = "DNS name"
  type        = string
}

# variable "cert_id" {}
