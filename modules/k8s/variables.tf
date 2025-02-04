variable "cloud_id" {
  description = "Cloud ID"
  type        = string
}
variable "folder_id" {
  description = "Folder ID"
  type        = string
}
variable "zone" {
  description = "Zone"
  type        = string
  default     = "ru-central1-a"
}

variable "network_id" {
  description = "ID of the VPC network"
  type        = string
}

variable "subnet_id" {
  description = "ID of subnet"
  type        = map(string)
}

variable "vpc_subnet_default" {
  description = "Map of subnet details"
  type        = map(object({
    zone = string
    id   = string
  }))
}

variable "master_version" {
  type        = string
  description = "Kubernetes version for master nodes"
  default     = "1.28"
}

variable "nodes_version" {
  type        = string
  description = "Kubernetes version for nodes"
  default     = "1.28"
}
variable "node_groups_defaults" {
  description = "Map of common default values for Node groups."
  type        = map(any)
  default = {
    platform_id   = "standard-v3"
    node_cores    = 2
    node_memory   = 2
    node_gpus     = 0
    core_fraction = 50
    disk_type     = "network-ssd"
    disk_size     = 32
    preemptible   = false
    nat           = false
    ipv4          = true
    ipv6          = false
    size          = 3
  }
}
