#!/opt/venv/bin/python
"""
SQL Server connectivity test script for Container Apps
Tests DNS resolution, network connectivity, and database authentication
"""

import pyodbc
import socket
import os
import sys
import json
import requests
from urllib.parse import quote

def get_key_vault_secret(secret_name, key_vault_name):
    """Get secret from Azure Key Vault using managed identity"""
    try:
        # Get access token using managed identity
        identity_endpoint = os.environ.get('IDENTITY_ENDPOINT')
        identity_header = os.environ.get('IDENTITY_HEADER')
        
        if not identity_endpoint or not identity_header:
            return None, "Managed identity endpoint not available"
        
        token_url = f"{identity_endpoint}?resource=https://vault.azure.net/&api-version=2019-08-01"
        headers = {'X-IDENTITY-HEADER': identity_header}
        
        token_response = requests.get(token_url, headers=headers)
        if token_response.status_code != 200:
            return None, f"Failed to get access token: {token_response.text}"
        
        access_token = token_response.json()['access_token']
        
        # Get secret from Key Vault
        secret_url = f"https://{key_vault_name}.vault.azure.net/secrets/{secret_name}?api-version=7.0"
        headers = {'Authorization': f'Bearer {access_token}'}
        
        secret_response = requests.get(secret_url, headers=headers)
        if secret_response.status_code != 200:
            return None, f"Failed to get secret: {secret_response.text}"
        
        return secret_response.json()['value'], None
    except Exception as e:
        return None, f"Error getting secret: {str(e)}"

def test_dns_resolution(hostname):
    """Test DNS resolution for a hostname"""
    try:
        ip_address = socket.gethostbyname(hostname)
        return True, ip_address, None
    except socket.gaierror as e:
        return False, None, str(e)

def test_port_connectivity(hostname, port=1433):
    """Test TCP connectivity to hostname:port"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(10)
        result = sock.connect_ex((hostname, port))
        sock.close()
        return result == 0, None if result == 0 else f"Connection failed with error code: {result}"
    except Exception as e:
        return False, str(e)

def test_sql_connection(server, database, username, password):
    """Test SQL Server database connection"""
    try:
        # Build connection string
        conn_str = (
            f"DRIVER={{ODBC Driver 17 for SQL Server}};"
            f"SERVER={server};"
            f"DATABASE={database};"
            f"UID={username};"
            f"PWD={password};"
            f"Encrypt=yes;"
            f"TrustServerCertificate=no;"
            f"Connection Timeout=30;"
        )
        
        # Attempt connection
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        # Test with a simple query
        cursor.execute("SELECT @@VERSION")
        version = cursor.fetchone()[0]
        
        cursor.close()
        conn.close()
        
        return True, version, None
    except Exception as e:
        return False, None, str(e)

def main():
    """Main testing function"""
    results = {
        "timestamp": "$(date -Iseconds)",
        "tests": {}
    }
    
    # Get configuration from environment variables
    sql_servers = [
        {
            "name": "sql1",
            "hostname": os.environ.get('SQL_SERVER_1_HOSTNAME', ''),
            "database": os.environ.get('SQL_DATABASE_1_NAME', 'testdb1')
        },
        {
            "name": "sql2", 
            "hostname": os.environ.get('SQL_SERVER_2_HOSTNAME', ''),
            "database": os.environ.get('SQL_DATABASE_2_NAME', 'testdb2')
        }
    ]
    
    username = os.environ.get('SQL_ADMIN_USERNAME', 'sqladmin')
    key_vault_name = os.environ.get('KEY_VAULT_NAME', '')
    
    # Get password from Key Vault
    password, kv_error = get_key_vault_secret('sql-admin-password', key_vault_name)
    if not password:
        results["key_vault_error"] = kv_error
        password = os.environ.get('SQL_ADMIN_PASSWORD', '')  # Fallback
    
    for server in sql_servers:
        if not server['hostname']:
            continue
            
        server_results = {
            "hostname": server['hostname'],
            "database": server['database']
        }
        
        # Test DNS resolution
        dns_success, ip_address, dns_error = test_dns_resolution(server['hostname'])
        server_results["dns"] = {
            "success": dns_success,
            "ip_address": ip_address,
            "error": dns_error
        }
        
        # Test port connectivity
        if dns_success:
            port_success, port_error = test_port_connectivity(server['hostname'])
            server_results["port_1433"] = {
                "success": port_success,
                "error": port_error
            }
            
            # Test SQL connection
            if port_success and password:
                sql_success, version, sql_error = test_sql_connection(
                    server['hostname'], server['database'], username, password
                )
                server_results["sql_connection"] = {
                    "success": sql_success,
                    "sql_version": version,
                    "error": sql_error
                }
        
        results["tests"][server['name']] = server_results
    
    # Output results as JSON
    print(json.dumps(results, indent=2))
    
    # Return appropriate exit code
    all_success = all(
        test.get("sql_connection", {}).get("success", False) 
        for test in results["tests"].values()
        if test.get("hostname")
    )
    sys.exit(0 if all_success else 1)

if __name__ == "__main__":
    main()