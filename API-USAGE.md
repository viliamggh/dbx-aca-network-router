# DBX ACA Network Router API - Usage Guide

## Overview
Your Container App has been optimized for programmatic API access. No web UI - just clean REST endpoints for network and database connectivity testing.

## API Endpoints

### Service Information
```bash
# Get service info and available endpoints
curl http://your-container-app-fqdn/

# Health check
curl http://your-container-app-fqdn/health

# Detailed system status
curl http://your-container-app-fqdn/status
```

### Testing Endpoints
```bash
# Run all tests (network + SQL)
curl http://your-container-app-fqdn/tests/all

# Network connectivity tests only
curl http://your-container-app-fqdn/tests/network

# SQL database connectivity tests only
curl http://your-container-app-fqdn/tests/sql

# Custom network command
curl -X POST http://your-container-app-fqdn/tests/custom \
  -H "Content-Type: application/json" \
  -d '{"command": "nslookup google.com"}'

# Custom command with timeout
curl -X POST http://your-container-app-fqdn/tests/custom \
  -H "Content-Type: application/json" \
  -d '{"command": "ping -c 3 8.8.8.8", "timeout": 60}'
```

### Information Endpoints
```bash
# Environment variables
curl http://your-container-app-fqdn/info/environment

# Service configuration
curl http://your-container-app-fqdn/info/config

# Network interface details
curl http://your-container-app-fqdn/info/network
```

## Access Methods (with internal_load_balancer_enabled = true)

Since your Container App Environment is internal, you have these options to access the API:

### Option 1: From Azure VM in the same VNet
```bash
# Create a test VM in your VNet
az vm create \
  --resource-group "dbx-aca-network-router-rg" \
  --name "test-vm" \
  --image "Ubuntu2204" \
  --vnet-name "dbx-aca-network-router-vnet" \
  --subnet "private-endpoint-subnet" \
  --admin-username "azureuser" \
  --generate-ssh-keys

# SSH into the VM and test the API
ssh azureuser@<vm-public-ip>
curl http://your-internal-container-app-fqdn/tests/all
```

### Option 2: From Databricks Notebook
```python
import requests
import json

# Test the API from within your Databricks workspace
base_url = "http://your-internal-container-app-fqdn"

# Run all tests
response = requests.get(f"{base_url}/tests/all")
print(json.dumps(response.json(), indent=2))

# Run custom network command
custom_test = {
    "command": "nslookup dbxacanetworkrouter-sql1-ne.database.windows.net"
}
response = requests.post(f"{base_url}/tests/custom", json=custom_test)
print(json.dumps(response.json(), indent=2))
```

### Option 3: From Container App itself (debugging)
```bash
# Exec into the running container
az containerapp exec \
  --name "dbxacanetworkrouteraca" \
  --resource-group "dbx-aca-network-router-rg" \
  --command "/bin/bash"

# Test locally inside the container
curl http://localhost:5000/tests/all
```

## Expected API Responses

### Successful Test Response
```json
{
  "test_suite": "comprehensive",
  "started_at": "2024-12-26T10:30:00.123456",
  "tests": {
    "network": {
      "status": "passed",
      "exit_code": 0,
      "output": "DNS resolution successful...",
      "errors": null
    },
    "sql": {
      "status": "passed", 
      "exit_code": 0,
      "structured_results": {
        "tests": {
          "sql1": {
            "sql_connection": {
              "success": true,
              "sql_version": "Microsoft SQL Azure..."
            }
          }
        }
      },
      "errors": null
    }
  },
  "summary": {
    "total_tests": 2,
    "passed": 2,
    "failed": 0,
    "errors": 0,
    "overall_status": "passed"
  },
  "completed_at": "2024-12-26T10:30:45.789012"
}
```

## Deployment Commands

```bash
# Build and push new API-optimized image
docker build --platform linux/amd64 -t dbxacanetworkrouteracr.azurecr.io/dbx-aca-network-test:v4 .
docker push dbxacanetworkrouteracr.azurecr.io/dbx-aca-network-test:v4

# Update Terraform with new image tag
# Edit terraform/variables.tf: image_tag = "v4"

# Apply Terraform changes
terraform plan
terraform apply
```

## Key Changes Made

1. **Removed nginx and web UI** - Pure API-only service
2. **Updated endpoints** - Cleaner REST API structure
3. **Enhanced logging** - Better structured logging for debugging
4. **Comprehensive testing** - /tests/all runs both network and SQL tests
5. **Security** - Runs as non-root user, whitelist for custom commands
6. **Health checks** - Built-in Docker health checks
7. **Better error handling** - Structured error responses with HTTP status codes

## Container App Port Changes
- **Old**: nginx on port 8080
- **New**: Flask API on port 5000 (mapped to external port via Container Apps)
- **Terraform updated**: `target_port = 5000`

Your Container App is now optimized for programmatic access with clean JSON responses and comprehensive testing capabilities!