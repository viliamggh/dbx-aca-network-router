#!/bin/bash

echo "Starting DBX ACA Network Router API..."

set -e

# Make sure scripts are executable
chmod +x /app/test_endpoints.sh
chmod +x /app/test_connectivity.py

# Show environment info
echo "Container Info:"
echo "  Hostname: $(hostname)"
echo "  Container IP: $(hostname -I | xargs || echo 'unknown')"
echo "  Python version: $(/opt/venv/bin/python --version)"

# Check if critical environment variables are set
echo "Environment Check:"
echo "  AZURE_CLIENT_ID: ${AZURE_CLIENT_ID:+set}"
echo "  SQL_SERVER_1_HOSTNAME: ${SQL_SERVER_1_HOSTNAME:+set}"
echo "  KEY_VAULT_NAME: ${KEY_VAULT_NAME:+set}"

# Start the API server (this will run in foreground)
echo "Starting API server on port 5000..."
echo "API will be available at:"
echo "  Internal: http://localhost:5000"
echo "  External: http://<container-app-fqdn>:5000"
echo ""
echo "Available endpoints:"
echo "  GET  /"
echo "  GET  /health"
echo "  GET  /status"
echo "  GET  /tests/all"
echo "  GET  /tests/network"
echo "  GET  /tests/sql"
echo "  POST /tests/custom"
echo "  GET  /info/environment"
echo ""

exec /opt/venv/bin/python /app/test_api_server.py