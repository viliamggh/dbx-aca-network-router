Databricks module

This module creates a Resource Group, VNet, two subnets (public/private) with Databricks delegation, NSGs, subnet associations and a Databricks workspace with VNet injection.

Required inputs
- project_name
- location
- vnet_address_space (list)
- public_subnet_address_prefix
- private_subnet_address_prefix

Optional inputs
- databricks_sku (default: premium)
- public_network_access_enabled (default: true)
- no_public_ip (default: false)
- storage_account_name (optional)

Outputs
- resource_group_name
- vnet_id
- workspace_id
- workspace_id

Example usage

module "databricks" {
  source = "./modules/databricks"

  project_name = "myproj"
  location = "westeurope"
  vnet_address_space = ["10.1.0.0/16"]
  public_subnet_address_prefix = "10.1.1.0/24"
  private_subnet_address_prefix = "10.1.2.0/24"
}
