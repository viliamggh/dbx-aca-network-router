
module "databricks1" {
  source = "./modules/databricks"

  rg_name = data.azurerm_resource_group.rg.name
  # Project naming (use existing var or literal)
  project_name = "${var.project_name_no_dash}dbx1"

  # Location and network layout (replace with your values)
  location                      = "westeurope"
  vnet_address_space            = ["10.2.0.0/16"]
  public_subnet_address_prefix  = "10.2.3.0/24"
  private_subnet_address_prefix = "10.2.4.0/24"
  # PE subnet must not overlap public/private subnets. Use a separate /27 outside those ranges.
  pe_subnet_address_prefix     = "10.2.5.0/27"

  # Databricks SKU and networking behavior
  databricks_sku                = "premium"
  public_network_access_enabled = true
  no_public_ip                  = true
}


module "databricks2" {
  source = "./modules/databricks"

  rg_name = data.azurerm_resource_group.rg.name
  # Project naming (use existing var or literal)
  project_name = "${var.project_name_no_dash}dbx2"

  # Location and network layout (replace with your values)
  location                      = "westeurope"
  vnet_address_space            = ["10.2.0.0/16"]
  public_subnet_address_prefix  = "10.2.1.0/24"
  private_subnet_address_prefix = "10.2.2.0/24"
  # PE subnet must not overlap public/private subnets. Use a separate /27 outside those ranges.
  pe_subnet_address_prefix     = "10.2.6.0/27"

  # Databricks SKU and networking behavior
  databricks_sku                = "premium"
  public_network_access_enabled = true
  no_public_ip                  = true
}
