variable "acr_name" {
  type = string
}

variable "rg_name" {
  type = string
}

variable "project_name_no_dash" {
  type = string
}

variable "image_name" {
  type = string
}

# variable "environment" {
#   type    = string
#   default = "main"
# }

variable "image_tag" {
  type = string
}

variable "vnet_cidr" {
  description = "VNet CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_app_subnet_cidr" {
  description = "Container App subnet CIDR (must be /27)"
  type        = string
  default     = "10.0.1.0/27"
}

variable "private_endpoint_subnet_cidr" {
  description = "Private endpoint subnet CIDR"
  type        = string
  default     = "10.0.2.0/24"
}

variable "sql_admin_username" {
  description = "SQL Server administrator username"
  type        = string
  default     = "sqladmin"
}

variable "db1_name" {
  description = "First database name"
  type        = string
  default     = "database1"
}

variable "db2_name" {
  description = "Second database name"
  type        = string
  default     = "database2"
}
