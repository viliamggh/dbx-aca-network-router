# Container App outputs
output "container_app_name" {
	description = "Name of the Azure Container App"
	value       = azurerm_container_app.aca.name
}

output "container_app_region" {
	description = "Region where the Azure Container App is deployed"
	value       = azurerm_container_app.aca.location
}

output "container_app_environment_id" {
	description = "ID of the Container App Environment"
	value       = azurerm_container_app_environment.c_app_env.id
}

output "container_registry_name" {
	description = "Name of the Azure Container Registry used for the app"
	value       = data.azurerm_container_registry.acr.name
}