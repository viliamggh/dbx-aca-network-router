
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
  pe_subnet_address_prefix = "10.2.5.0/27"

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
  pe_subnet_address_prefix = "10.2.6.0/27"

  # Databricks SKU and networking behavior
  databricks_sku                = "premium"
  public_network_access_enabled = true
  no_public_ip                  = true
}


# resource "azurerm_private_dns_zone" "dbx_override" {
#   name                = "database.windows.net"
#   resource_group_name = data.azurerm_resource_group.rg.name
# }

# resource "azurerm_private_dns_a_record" "sql1_to_aca" {
#   name                = azurerm_mssql_server.sql_server_1.name                # "dbxacanetworkrouter-sql1-ne"
#   zone_name           = azurerm_private_dns_zone.dbx_override.name
#   resource_group_name = data.azurerm_resource_group.rg.name
#   ttl                 = 30
#   records             = ["10.2.5.4"]                   # <- ACA private IP
# }

# resource "azurerm_private_dns_a_record" "sql2_to_aca" {
#   name                = azurerm_mssql_server.sql_server_2.name
#   zone_name           = azurerm_private_dns_zone.dbx_override.name
#   resource_group_name = data.azurerm_resource_group.rg.name
#   ttl                 = 30
#   records             = ["10.2.5.4"]                   # <- ACA private IP
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "dbx_override_link" {
#   name                  = "dbx-database-windows-net-link"
#   resource_group_name   = data.azurerm_resource_group.rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.dbx_override.name
#   virtual_network_id    = module.databricks1.vnet_id
#   registration_enabled  = false
# }

