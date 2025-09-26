output "resource_group_name" {
  value = data.azurerm_resource_group.main.name
}

output "vnet_id" {
  value = azurerm_virtual_network.databricks.id
}

output "workspace_id" {
  value = azurerm_databricks_workspace.main.id
}

output "workspace_workspace_id" {
  value = azurerm_databricks_workspace.main.workspace_id
}

output "workspace_name" {
  value = azurerm_databricks_workspace.main.name
}

output "pe_subnet_id" {
  value = length(azurerm_subnet.databricks_pe) > 0 ? azurerm_subnet.databricks_pe[0].id : ""
}

output "vnet_name" {
  value = azurerm_virtual_network.databricks.name
}
