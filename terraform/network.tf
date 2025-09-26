# Virtual Network for Container Apps and Private Endpoints
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name_no_dash}-vnet"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  address_space       = [var.vnet_cidr]

  
}

# Container App subnet (delegated, /27 size)
resource "azurerm_subnet" "container_app_subnet" {
  name                 = "container-app-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.container_app_subnet_cidr]

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# Private endpoint subnet
resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = "private-endpoint-subnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_endpoint_subnet_cidr]
}

# Private DNS Zone for SQL Database
resource "azurerm_private_dns_zone" "sql_dns_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name

  
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name                  = "${var.project_name_no_dash}-sql-dns-link"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
 
}

# Private DNS Zone for Container Apps
resource "azurerm_private_dns_zone" "aca_dns_zone" {
  name                = "privatelink.${lower(replace(data.azurerm_resource_group.rg.location, " ", ""))}.azurecontainerapps.io"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Link Container App DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "aca_dns_link" {
  name                  = "${var.project_name_no_dash}-aca-dns-link"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.aca_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false
}