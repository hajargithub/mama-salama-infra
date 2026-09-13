variable "subscription_id" {
  description = "Azure subscription used for the Terraform state resources."
  type        = string
}

variable "location" {
  description = "Azure region for the Terraform state resources."
  type        = string
  default     = "France Central"
}

variable "project_name" {
  description = "Short project name used in resource names."
  type        = string
  default     = "mama-salama"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "pfe"
}

variable "tags" {
  description = "Additional tags applied to all bootstrap resources."
  type        = map(string)
  default     = {}
}

variable "ci_principal_id" {
  description = "Optional object ID of the GitHub OIDC service principal or managed identity."
  type        = string
  default     = null
}
