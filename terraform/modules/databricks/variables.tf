variable "project_name" {
  type = string
}

variable "rg_suffix" {
  type    = string
  default = "1"
}

variable "location" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "public_subnet_address_prefix" {
  type = string
}

variable "private_subnet_address_prefix" {
  type = string
}

variable "databricks_sku" {
  type    = string
  default = "premium"
}

variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "no_public_ip" {
  type    = bool
  default = false
}

variable "storage_account_name" {
  type    = string
  default = ""
}

variable "storage_account_sku_name" {
  type    = string
  default = "Standard_LRS"
}

# Optional metastore id if you want the module to create assignment
variable "metastore_id" {
  type    = string
  default = ""
}

variable "pe_subnet_address_prefix" {
  description = "Optional private endpoint (PE) subnet prefix (CIDR). If provided, a /27 PE subnet will be created in the VNet."
  type        = string
  default     = ""
}

variable "rg_name" {
    type = string
}