# DBX-ACA Network Router

This project demonstrates a secure network routing architecture in Azure, enabling Databricks workspaces to connect to SQL databases via a Container App running an Nginx reverse proxy. It focuses on private networking, and connection to datasources directly from Databricks.

## Architecture Overview

The setup includes:
- **Two Databricks Workspaces**: Deployed with VNet injection in separate VNets (10.2.0.0/16 and 10.1.0.0/16), using Premium SKU for secure access.
- **Container App Environment**: Internal load balancer with Nginx proxy, exposing ports 5433 (PG1) and 5434 (PG2) for TCP traffic.
- **PostgreSQL Flexible Servers**: Two servers (PG1 and PG2) in North Europe, with private endpoints for secure access (to simulate routing via their private IPs)
- **Networking**: Shared VNet (10.0.0.0/16) with private DNS zones, private endpoints, and NSGs for isolation. (this is usually already set up within enterprise networking)
- **Security**: Managed identity for authentication, RBAC.
- **CI/CD**: GitHub Actions for automated builds and Terraform deployments.

Key features:
- Private connectivity.
- Traffic routing via Nginx upstreams.
- Provide a way for "address-space-greedy Databricks workspaces" to connect to the datasources privately, suitable for HUB-SPOKE network architecture.

## Prerequisites

- Azure subscription with permissions for resource creation.
- Terraform >= 1.6.0 and azurerm provider >= 3.110.0.
- Docker for building images.
- GitHub repository with secrets/variables set via [infra_base.sh](infra_base.sh).

## Quick Start

1. **Bootstrap Infrastructure**:
   ```bash
   ./infra_base.sh  # Creates RG, UAMI, storage, ACR, and sets GitHub variables
   ```

2. **Commit and Push Changes**:
   ```bash
   git add .
   git commit -m "Deploy infrastructure"
   git push origin main
   ```

3. **Monitor GitHub Actions**:
   - The GitHub workflow will automatically trigger
   - Image build and Terraform deployment happen automatically
   - Monitor progress in the Actions tab

4. **Access Deployed Resources**:
   - Use Terraform outputs to get resource details
   - Access OF Container App's internal FQDN only possible from internal Azure network

## Configuration

### Variables
Key variables in [terraform/variables.tf](terraform/variables.tf):
- `project_name_no_dash`: Base name for resources (e.g., "dbxacanetworkrouter").
- `rg_name`: Resource group name.
- `acr_name`: Azure Container Registry name.
- `vnet_cidr`: Main VNet CIDR (default: 10.0.0.0/16).
- `sql_admin_username`: Admin user for PostgreSQL (default: "sqladmin").

### Modules
- **Databricks Module** ([terraform/modules/databricks/](terraform/modules/databricks/)): Creates workspace with VNet injection, subnets, and NSGs.

### Networking Details
- Container App subnet: Delegated /27.
- Private endpoint subnet: /24 for PE connections.
- DNS zones: `privatelink.database.windows.net` for PG, `privatelink.westeurope.azurecontainerapps.io` for ACA.

## Deployment
- **CI/CD**: GitHub Actions in [.github/workflows/deploy.yaml](.github/workflows/deploy.yaml) handles image build, push, and infra apply.
- **Local**: Use Terraform CLI with azurerm backend.

## Security & Best Practices

- Private networking by default; no public IPs for Databricks or SQL Servers.
- Managed identity for Container App access to ACR and Key Vault.
- RBAC with minimal permissions (e.g., AcrPull, Key Vault Secrets User).

## Databricks JDBC Connection

Connect to PostgreSQL databases through the Container App reverse proxy using JDBC. The proxy routes traffic based on port numbers:

- **Port 5433**: Routes to PostgreSQL Server 1 (database1)
- **Port 5434**: Routes to PostgreSQL Server 2 (database2)

### Connect to Database 1 (Port 5433)

```python
# endpoint can obtained for example from Az Portal: ACA -> Networking -> Ingress -> Endpoints
# or terraform outputs
aca_fqdn = "dbxacanetworkrouteraca.bravesea-ccfe9f04.westeurope.azurecontainerapps.io"
pg_user = "sqladmin"
pg_pass = "xxxxxxxx" # to be loaded from dbx secret scope
db1_name = "database1"

jdbc_props = {
    "user": pg_user,
    "password": pg_pass,
    "driver": "org.postgresql.Driver"
}

url1 = f"jdbc:postgresql://{aca_fqdn}:5433/{db1_name}?sslmode=require"
df_test = spark.read.jdbc(url=url1, table="demo.employees", properties=jdbc_props)
df_test.show()
```

### Connect to Database 2 (Port 5434)

```python
# endpoint can obtained for example from Az Portal: ACA -> Networking -> Ingress -> Endpoints
# or terraform outputs
aca_fqdn = "dbxacanetworkrouteraca.bravesea-ccfe9f04.westeurope.azurecontainerapps.io"
pg_user = "sqladmin"
pg_pass = "xxxxxxx" # to be loaded from dbx secret scope
db2_name = "database2"

jdbc_props = {
    "user": pg_user,
    "password": pg_pass,
    "driver": "org.postgresql.Driver"
}

url2 = f"jdbc:postgresql://{aca_fqdn}:5434/{db2_name}?sslmode=require"
df_test = spark.read.jdbc(url=url2, table="demo.employees", properties=jdbc_props)
df_test.show()
```