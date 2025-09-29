# # Generate random passwords for SQL servers
# resource "random_password" "sql_password" {
#   length  = 16
#   special = true
# }

# # Store SQL admin password in Key Vault
# resource "azurerm_key_vault_secret" "sql_admin_password" {
#   name         = "sql-admin-password"
#   value        = random_password.sql_password.result
#   key_vault_id = azurerm_key_vault.kv.id

#   depends_on = [
#     azurerm_key_vault.kv,
#     azurerm_role_assignment.kv_rbac_current_user
#   ]
# }

# # First SQL Server
# resource "azurerm_mssql_server" "sql_server_1" {
#   name                          = "${var.project_name_no_dash}-sql1-ne"
#   resource_group_name           = data.azurerm_resource_group.rg.name
#   location                      = "northeurope"
#   version                       = "12.0"
#   administrator_login           = var.sql_admin_username
#   administrator_login_password  = random_password.sql_password.result
#   minimum_tls_version           = "1.2"
#   public_network_access_enabled = false

  
# }

# # First Database
# resource "azurerm_mssql_database" "database_1" {
#   name         = var.db1_name
#   server_id    = azurerm_mssql_server.sql_server_1.id
#   collation    = "SQL_Latin1_General_CP1_CI_AS"
#   license_type = "LicenseIncluded"
#   max_size_gb  = 2
#   sku_name     = "Basic"

  
# }

# # Second SQL Server
# resource "azurerm_mssql_server" "sql_server_2" {
#   name                          = "${var.project_name_no_dash}-sql2-ne"
#   resource_group_name           = data.azurerm_resource_group.rg.name
#   location                      = "northeurope"
#   version                       = "12.0"
#   administrator_login           = var.sql_admin_username
#   administrator_login_password  = random_password.sql_password.result
#   minimum_tls_version           = "1.2"
#   public_network_access_enabled = false

  
# }

# # Second Database
# resource "azurerm_mssql_database" "database_2" {
#   name         = var.db2_name
#   server_id    = azurerm_mssql_server.sql_server_2.id
#   collation    = "SQL_Latin1_General_CP1_CI_AS"
#   license_type = "LicenseIncluded"
#   max_size_gb  = 2
#   sku_name     = "Basic"

  
# }

# # Private Endpoint for first SQL Server
# resource "azurerm_private_endpoint" "sql_pe_1" {
#   name                = "${var.project_name_no_dash}-sql1-pe"
#   location            = data.azurerm_resource_group.rg.location
#   resource_group_name = data.azurerm_resource_group.rg.name
#   subnet_id           = azurerm_subnet.private_endpoint_subnet.id

#   private_service_connection {
#     name                           = "${var.project_name_no_dash}-sql1-psc"
#     private_connection_resource_id = azurerm_mssql_server.sql_server_1.id
#     subresource_names              = ["sqlServer"]
#     is_manual_connection           = false
#   }

#   private_dns_zone_group {
#     name                 = "${var.project_name_no_dash}-sql1-dns-zone-group"
#     private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns_zone.id]
#   }

  
# }

# # Private Endpoint for second SQL Server
# resource "azurerm_private_endpoint" "sql_pe_2" {
#   name                = "${var.project_name_no_dash}-sql2-pe"
#   location            = data.azurerm_resource_group.rg.location
#   resource_group_name = data.azurerm_resource_group.rg.name
#   subnet_id           = azurerm_subnet.private_endpoint_subnet.id

#   private_service_connection {
#     name                           = "${var.project_name_no_dash}-sql2-psc"
#     private_connection_resource_id = azurerm_mssql_server.sql_server_2.id
#     subresource_names              = ["sqlServer"]
#     is_manual_connection           = false
#   }

#   private_dns_zone_group {
#     name                 = "${var.project_name_no_dash}-sql2-dns-zone-group"
#     private_dns_zone_ids = [azurerm_private_dns_zone.sql_dns_zone.id]
#   }

  
# }



############################
# Password in Key Vault
############################
resource "random_password" "pg_password" {
  length  = 20
  special = true
}

resource "azurerm_key_vault_secret" "pg_admin_password" {
  name         = "pg-admin-password"
  value        = random_password.pg_password.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault.kv,
    azurerm_role_assignment.kv_rbac_current_user
  ]
}

############################
# Private DNS zone for Private Link
############################
resource "azurerm_private_dns_zone" "pg_privatelink" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Link the zone to the VNet that contains your Private Endpoint subnet
data "azurerm_virtual_network" "pe_vnet" {
  name                = azurerm_subnet.private_endpoint_subnet.virtual_network_name
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg_privatelink_link" {
  name                  = "${var.project_name_no_dash}-pg-privatelink-link"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pg_privatelink.name
  virtual_network_id    = data.azurerm_virtual_network.pe_vnet.id
  registration_enabled  = false
}

############################
# PostgreSQL Flexible Server #1 (Public access mode)
############################
resource "azurerm_postgresql_flexible_server" "pg1" {
  name                   = "${var.project_name_no_dash}-pg1-ne"
  resource_group_name    = data.azurerm_resource_group.rg.name
  location               = "northeurope"
  zone = 2

  version                = "16"
  administrator_login    = var.sql_admin_username
  administrator_password = random_password.pg_password.result

  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768

  # IMPORTANT: For Private Endpoint you must use the "Public access" networking mode
  # i.e. DO NOT set delegated_subnet_id/private_dns_zone_id.
  # Keep public network enabled but don't create any firewall rules => no public ingress.
  public_network_access_enabled = true

  authentication {
    password_auth_enabled = true
  }

  tags = { workload = "db1" }
}

resource "azurerm_postgresql_flexible_server_database" "pgdb1" {
  name      = var.db1_name
  server_id = azurerm_postgresql_flexible_server.pg1.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Private Endpoint for PG #1
resource "azurerm_private_endpoint" "pg1_pe" {
  name                = "${var.project_name_no_dash}-pg1-pe"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "${var.project_name_no_dash}-pg1-psc"
    private_connection_resource_id = azurerm_postgresql_flexible_server.pg1.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.project_name_no_dash}-pg1-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.pg_privatelink.id]
  }
}

############################
# PostgreSQL Flexible Server #2 (Public access mode)
############################
resource "azurerm_postgresql_flexible_server" "pg2" {
  name                   = "${var.project_name_no_dash}-pg2-ne"
  resource_group_name    = data.azurerm_resource_group.rg.name
  location               = "northeurope"
  zone = 2

  version                = "16"
  administrator_login    = var.sql_admin_username
  administrator_password = random_password.pg_password.result

  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768

  public_network_access_enabled = true

  authentication {
    password_auth_enabled = true
  }

  tags = { workload = "db2" }
}

resource "azurerm_postgresql_flexible_server_database" "pgdb2" {
  name      = var.db2_name
  server_id = azurerm_postgresql_flexible_server.pg2.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Private Endpoint for PG #2
resource "azurerm_private_endpoint" "pg2_pe" {
  name                = "${var.project_name_no_dash}-pg2-pe"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.private_endpoint_subnet.id

  private_service_connection {
    name                           = "${var.project_name_no_dash}-pg2-psc"
    private_connection_resource_id = azurerm_postgresql_flexible_server.pg2.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.project_name_no_dash}-pg2-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.pg_privatelink.id]
  }
}

############################
# (Optional) Outputs
############################
output "pg1_fqdn" { value = azurerm_postgresql_flexible_server.pg1.fqdn }
output "pg2_fqdn" { value = azurerm_postgresql_flexible_server.pg2.fqdn }

# Private endpoint IPs (handy if you want NGINX to target IPs)
output "pg1_pe_ip" {
  value = azurerm_private_endpoint.pg1_pe.private_service_connection[0].private_ip_address
}
output "pg2_pe_ip" {
  value = azurerm_private_endpoint.pg2_pe.private_service_connection[0].private_ip_address
}
