resource "azurerm_container_app" "aca" {
  name                         = "${var.project_name_no_dash}aca"
  container_app_environment_id = azurerm_container_app_environment.c_app_env.id
  resource_group_name          = data.azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.c_app_identity.id]
  }

  ingress {
    external_enabled           = true
    # allow_insecure_connections = true
    transport                  = "tcp"
    target_port                = 1433
    exposed_port               = 1433
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.c_app_identity.id
  }
  template {
    container {
      name   = replace(var.image_name, "_", "")
      image  = "${data.azurerm_container_registry.acr.login_server}/${var.image_name}:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      # Managed Identity configuration for Key Vault access
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.c_app_identity.client_id
      }

      env {
        name  = "AZURE_TENANT_ID"
        value = azurerm_user_assigned_identity.c_app_identity.tenant_id
      }

      # SQL Server connection configuration
      env {
        name  = "SQL_SERVER_1_HOSTNAME"
        value = azurerm_mssql_server.sql_server_1.fully_qualified_domain_name
      }

      env {
        name  = "SQL_SERVER_2_HOSTNAME" 
        value = azurerm_mssql_server.sql_server_2.fully_qualified_domain_name
      }

      env {
        name  = "SQL_DATABASE_1_NAME"
        value = azurerm_mssql_database.database_1.name
      }

      env {
        name  = "SQL_DATABASE_2_NAME"
        value = azurerm_mssql_database.database_2.name
      }

      env {
        name  = "SQL_ADMIN_USERNAME"
        value = var.sql_admin_username
      }

      env {
        name  = "KEY_VAULT_NAME"
        value = azurerm_key_vault.kv.name
      }
    }
  }

}


# Private Endpoint for ACA
resource "azurerm_private_endpoint" "aca_pe_1" {
  name                = "${var.project_name_no_dash}-aca-pe1"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = module.databricks1.pe_subnet_id

  private_service_connection {
    name                           = "${var.project_name_no_dash}-aca-psc"
    private_connection_resource_id = azurerm_container_app_environment.c_app_env.id
    subresource_names              = ["managedEnvironments"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.project_name_no_dash}-aca-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.aca_dns_zone.id]
  }

  
}