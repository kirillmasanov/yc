variable "folder_id" {
  description = "Folder ID"
  type        = string
}

variable "db_hostname" {
  description = "DataBase hostname"
  type        = string
}

variable "db_name" {
  description = "DataBase name"
  type        = string
}

variable "db_user" {
  description = "DataBase user"
  type        = string
}

variable "db_password" {
  description = "User password"
  type        = string
}

variable "alb_log_group_id" {
  description = "ID of default logging group of ALB"
  type        = string
}
