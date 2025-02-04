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

variable "dns" {
  description = "DNS name"
  type        = string
}
