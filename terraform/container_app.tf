resource "azurerm_container_app" "aca" {
  name                         = "${var.project_name_no_dash}aca"
  container_app_environment_id = azurerm_container_app_environment.c_app_env.id
  resource_group_name          = data.azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.c_app_identity.id]
  }
  # identity {
  #   type = "SystemAssigned"
  # }

  ingress {
    external_enabled           = true
    allow_insecure_connections = true
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
    target_port = 8080
    # ip_security_restriction {
    #   name             = "my_machine"
    #   action           = "Allow"
    #   ip_address_range = "109.81.89.47"
    # }
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

      # env {
      #   name  = "AZURE_CLIENT_ID"
      #   value = azurerm_user_assigned_identity.c_app_identity.client_id
      # }

      # env {
      #   name  = "AZURE_TENANT_ID"
      #   value = azurerm_user_assigned_identity.c_app_identity.tenant_id
      # }
    }
  }

}