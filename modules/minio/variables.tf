variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "container_app_environment_id" {
  type = string
}

variable "image" {
  type = string
}

variable "registry_server" {
  type = string
}

variable "registry_id" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_account_access_key" {
  type      = string
  sensitive = true
}

variable "storage_share_name" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "root_user_secret_id" {
  type = string
}

variable "root_password_secret_id" {
  type = string
}

variable "cpu" {
  type    = number
  default = 0.5
}

variable "memory" {
  type    = string
  default = "1Gi"
}

variable "tags" {
  type    = map(string)
  default = {}
}