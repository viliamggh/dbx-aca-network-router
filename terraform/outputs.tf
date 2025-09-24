# # Network outputs
# output "vnet_id" {
#   description = "ID of the Virtual Network"
#   value       = azurerm_virtual_network.main.id
# }

# output "vnet_name" {
#   description = "Name of the Virtual Network"
#   value       = azurerm_virtual_network.main.name
# }

# output "container_app_subnet_id" {
#   description = "ID of the Container App subnet"
#   value       = azurerm_subnet.container_app_subnet.id
# }

# output "private_endpoint_subnet_id" {
#   description = "ID of the Private Endpoint subnet"
#   value       = azurerm_subnet.private_endpoint_subnet.id
# }

# # SQL Database outputs
# output "sql_server_1_fqdn" {
#   description = "Fully qualified domain name of the first SQL server"
#   value       = azurerm_mssql_server.sql_server_1.fully_qualified_domain_name
# }

# output "sql_server_2_fqdn" {
#   description = "Fully qualified domain name of the second SQL server"
#   value       = azurerm_mssql_server.sql_server_2.fully_qualified_domain_name
# }

# output "sql_server_1_id" {
#   description = "ID of the first SQL server"
#   value       = azurerm_mssql_server.sql_server_1.id
# }

# output "sql_server_2_id" {
#   description = "ID of the second SQL server"
#   value       = azurerm_mssql_server.sql_server_2.id
# }

# output "database_1_id" {
#   description = "ID of the first database"
#   value       = azurerm_mssql_database.database_1.id
# }

# output "database_2_id" {
#   description = "ID of the second database"
#   value       = azurerm_mssql_database.database_2.id
# }

# # Private Endpoint outputs
# output "sql_pe_1_private_ip" {
#   description = "Private IP address of the first SQL server private endpoint"
#   value       = azurerm_private_endpoint.sql_pe_1.private_service_connection[0].private_ip_address
# }

# output "sql_pe_2_private_ip" {
#   description = "Private IP address of the second SQL server private endpoint"
#   value       = azurerm_private_endpoint.sql_pe_2.private_service_connection[0].private_ip_address
# }

# # Private DNS Zone output
# output "sql_private_dns_zone_name" {
#   description = "Name of the SQL private DNS zone"
#   value       = azurerm_private_dns_zone.sql_dns_zone.name
# }

# # Key Vault reference for password
# output "sql_admin_username" {
#   description = "SQL Server administrator username"
#   value       = var.sql_admin_username
# }

# output "key_vault_secret_sql_password_id" {
#   description = "Key Vault secret ID for SQL admin password"
#   value       = azurerm_key_vault_secret.sql_admin_password.id
#   sensitive   = true
# }