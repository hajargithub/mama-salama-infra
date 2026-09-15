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
  default     = "acrmamasalamapfey4yy6.azurecr.io/mama-salama-backend@sha256:f9a5ff69304726ba9e61cd93d355974e66df47e94d649c126b717278b348b52f"
}

variable "backend_port" {
  description = "Port exposed by the backend container."
  type        = number
  default     = 8081
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
variable "enable_minio" {
  description = "Active ou désactive le déploiement de MinIO"
  type        = bool
  default     = false
}

variable "minio_image" {
  description = "Image Docker immuable de MinIO stockée dans Azure Container Registry"
  type        = string
  default     = "acrmamasalamapfey4yy6.azurecr.io/mama-salama-minio@sha256:a1a8bd4ac40ad7881a245bab97323e18f971e4d4cba2c2007ec1bedd21cbaba2"
}
variable "enable_discovery" {
  description = "Active ou désactive le Service Discovery Eureka"
  type        = bool
  default     = false
}

variable "discovery_image" {
  description = "Image Docker immuable du Service Discovery"
  type        = string
  default     = "acrmamasalamapfey4yy6.azurecr.io/mama-salama-discovery@sha256:97e09b20b581e4b0364350ef0c4e7a6c12343c4f870221caddde121701342ef4"
}
variable "frontend_url" {
  description = "Adresse du frontend utilisée dans les emails"
  type        = string
  default     = "http://localhost:5173"
}

variable "minio_bucket_name" {
  description = "Nom du bucket MinIO utilisé par le backend"
  type        = string
  default     = "mama-salama"
}
variable "enable_gateway" {
  description = "Active ou désactive l'API Gateway publique"
  type        = bool
  default     = false
}

variable "gateway_image" {
  description = "Image Docker immuable de l'API Gateway"
  type        = string
  default     = "acrmamasalamapfey4yy6.azurecr.io/mama-salama-gateway@sha256:fb4dba2413d415a6fe8d609d3b5e02b07ed2cb8aa1c932a6f5f635eaa878c5bd"
}

variable "gateway_port" {
  description = "Port exposé par l'API Gateway"
  type        = number
  default     = 8080
}