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

variable "container_name" {
  type = string
}

variable "image" {
  type = string
}

variable "target_port" {
  type = number
}

variable "registry_server" {
  type = string
}

variable "registry_id" {
  type = string
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "cpu" {
  type    = number
  default = 0.5
}

variable "memory" {
  type    = string
  default = "1Gi"
}

variable "min_replicas" {
  type    = number
  default = 0
}

variable "max_replicas" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "external_enabled" {
  description = "Autorise ou interdit l'accès public à la Container App"
  type        = bool
  default     = false
}
