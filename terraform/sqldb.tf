# Generate random passwords for SQL servers
resource "random_password" "sql_password" {
  length  = 16
  special = true
}

# Store SQL admin password in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_password.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault.kv
  ]
}

# First SQL Server
resource "azurerm_mssql_server" "sql_server_1" {
  name                          = "${var.project_name_no_dash}-sql1"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_username
  administrator_login_password  = random_password.sql_password.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false

  
}

# First Database
resource "azurerm_mssql_database" "database_1" {
  name         = var.db1_name
  server_id    = azurerm_mssql_server.sql_server_1.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "Basic"

  
}

# Second SQL Server
resource "azurerm_mssql_server" "sql_server_2" {
  name                          = "${var.project_name_no_dash}-sql2"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_username
  administrator_login_password  = random_password.sql_password.result
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false

  
}

# Second Database
resource "azurerm_mssql_database" "database_2" {
  name         = var.db2_name
  server_id    = azurerm_mssql_server.sql_server_2.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "Basic"

  
}

# Private Endpoint for first SQL Server
resource "azurerm_private_endpoint" "sql_pe_1" {
  name                = "${var.project_name_no_dash}-sql1-pe"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "${var.project_name_no_dash}-sql1-psc"
    private_connection_resource_id = azurerm_mssql_server.sql_server_1.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.project_name_no_dash}-sql1-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns_zone.id]
  }

  
}

# Private Endpoint for second SQL Server
resource "azurerm_private_endpoint" "sql_pe_2" {
  name                = "${var.project_name_no_dash}-sql2-pe"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "${var.project_name_no_dash}-sql2-psc"
    private_connection_resource_id = azurerm_mssql_server.sql_server_2.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.project_name_no_dash}-sql2-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns_zone.id]
  }

  
}
