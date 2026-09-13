variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "location" {
  description = "Primary Azure region."
  type        = string
  default     = "France Central"
}

variable "project_name" {
  description = "Project name used for naming and tagging."
  type        = string
  default     = "mama-salama"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "pfe"
}

variable "tags" {
  description = "Additional Azure tags."
  type        = map(string)
  default     = {}
}

variable "enable_postgres" {
  description = "Create Azure Database for PostgreSQL Flexible Server. Enable after confirming the backend database."
  type        = bool
  default     = false
}

variable "enable_backend" {
  description = "Create the backend Container App. Enable after auditing and publishing its image."
  type        = bool
  default     = false
}

variable "enable_frontend" {
  description = "Create Azure Static Web Apps. Enable only if the frontend is compatible."
  type        = bool
  default     = false
}

variable "backend_image" {
  description = "Full backend container image reference."
  type        = string
  default     = ""
}

variable "backend_port" {
  description = "Port exposed by the backend container."
  type        = number
  default     = 8080
}

variable "backend_env" {
  description = "Non-sensitive environment variables for the backend."
  type        = map(string)
  default     = {}
}

variable "postgres_database_name" {
  description = "Application database name."
  type        = string
  default     = "mamasalama"
}

variable "postgres_admin_username" {
  description = "PostgreSQL administrator username."
  type        = string
  default     = "mamasalama_admin"
}

variable "postgres_sku_name" {
  description = "PostgreSQL SKU. B_Standard_B1ms is suitable for a small PFE environment."
  type        = string
  default     = "B_Standard_B1ms"
}
