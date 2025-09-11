

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "databricks" {
  name                = "${var.project_name}-databricks-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "databricks_public" {
  name                 = "${var.project_name}-databricks-public-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.databricks.name
  address_prefixes     = [var.public_subnet_address_prefix]

  delegation {
    name = "databricks-delegation"
    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet" "databricks_private" {
  name                 = "${var.project_name}-databricks-private-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.databricks.name
  address_prefixes     = [var.private_subnet_address_prefix]

  delegation {
    name = "databricks-delegation"
    service_delegation {
      name    = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

# Optional private endpoint subnet (small /27) for private endpoints or reserved PE usage
resource "azurerm_subnet" "databricks_pe" {
  count                = var.pe_subnet_address_prefix == "" ? 0 : 1
  name                 = "${var.project_name}-databricks-pe-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.databricks.name
  address_prefixes     = [var.pe_subnet_address_prefix]
}

resource "azurerm_network_security_group" "databricks_public" {
  name                = "${var.project_name}-databricks-public-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "databricks_private" {
  name                = "${var.project_name}-databricks-private-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet_network_security_group_association" "databricks_public" {
  subnet_id                 = azurerm_subnet.databricks_public.id
  network_security_group_id = azurerm_network_security_group.databricks_public.id
}

resource "azurerm_subnet_network_security_group_association" "databricks_private" {
  subnet_id                 = azurerm_subnet.databricks_private.id
  network_security_group_id = azurerm_network_security_group.databricks_private.id
}

resource "azurerm_databricks_workspace" "main" {
  name                          = "${var.project_name}-dbw"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  sku                           = var.databricks_sku
  managed_resource_group_name   = "${var.project_name}-databricks-managed-rg"

  public_network_access_enabled = var.public_network_access_enabled

  custom_parameters {
    virtual_network_id                                   = azurerm_virtual_network.databricks.id
    public_subnet_name                                   = azurerm_subnet.databricks_public.name
    private_subnet_name                                  = azurerm_subnet.databricks_private.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.databricks_public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.databricks_private.id

    no_public_ip = var.no_public_ip

    storage_account_name     = var.storage_account_name
    storage_account_sku_name = var.storage_account_sku_name
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.databricks_public,
    azurerm_subnet_network_security_group_association.databricks_private,
  ]
}