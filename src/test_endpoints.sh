#!/bin/bash
"""
Network connectivity test script for Container Apps
Tests basic network connectivity and DNS resolution
"""

set -e

echo "=== Container App Network Connectivity Tests ==="
echo "Timestamp: $(date -Iseconds)"
echo

# Test DNS resolution
test_dns() {
    local hostname=$1
    echo "Testing DNS resolution for: $hostname"
    
    if nslookup "$hostname" > /dev/null 2>&1; then
        local ip=$(nslookup "$hostname" | grep -A1 "Name:" | tail -1 | awk '{print $2}')
        echo "✅ DNS resolution successful: $hostname -> $ip"
        return 0
    else
        echo "❌ DNS resolution failed for: $hostname"
        return 1
    fi
}

# Test port connectivity
test_port() {
    local hostname=$1
    local port=${2:-1433}
    echo "Testing port connectivity: $hostname:$port"
    
    if nc -z -v -w5 "$hostname" "$port" 2>/dev/null; then
        echo "✅ Port $port is reachable on $hostname"
        return 0
    else
        echo "❌ Port $port is NOT reachable on $hostname"
        return 1
    fi
}

# Test HTTP connectivity (for testing purposes)
test_http() {
    local url=$1
    echo "Testing HTTP connectivity: $url"
    
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200"; then
        echo "✅ HTTP connectivity successful to $url"
        return 0
    else
        echo "❌ HTTP connectivity failed to $url"
        return 1
    fi
}

# Main test execution
main() {
    local sql1_hostname="${SQL_SERVER_1_HOSTNAME:-}"
    local sql2_hostname="${SQL_SERVER_2_HOSTNAME:-}"
    
    echo "Environment variables:"
    echo "SQL_SERVER_1_HOSTNAME: $sql1_hostname"
    echo "SQL_SERVER_2_HOSTNAME: $sql2_hostname"
    echo "SQL_ADMIN_USERNAME: ${SQL_ADMIN_USERNAME:-}"
    echo "KEY_VAULT_NAME: ${KEY_VAULT_NAME:-}"
    echo
    
    local all_tests_passed=true
    
    # Test SQL Server 1
    if [[ -n "$sql1_hostname" ]]; then
        echo "=== Testing SQL Server 1 ==="
        test_dns "$sql1_hostname" || all_tests_passed=false
        test_port "$sql1_hostname" 1433 || all_tests_passed=false
        echo
    fi
    
    # Test SQL Server 2  
    if [[ -n "$sql2_hostname" ]]; then
        echo "=== Testing SQL Server 2 ==="
        test_dns "$sql2_hostname" || all_tests_passed=false
        test_port "$sql2_hostname" 1433 || all_tests_passed=false
        echo
    fi
    
    # Test external connectivity (as baseline)
    echo "=== Testing External Connectivity (Baseline) ==="
    test_dns "google.com" || all_tests_passed=false
    test_http "https://httpbin.org/status/200" || all_tests_passed=false
    echo
    
    # Network interface information
    echo "=== Network Interface Information ==="
    ip addr show
    echo
    
    echo "=== Route Table ==="
    ip route show
    echo
    
    if $all_tests_passed; then
        echo "🎉 All network tests passed!"
        exit 0
    else
        echo "⚠️  Some network tests failed!"
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    "dns")
        test_dns "$2"
        ;;
    "port")
        test_port "$2" "$3"
        ;;
    "http")
        test_http "$2"
        ;;
    *)
        main
        ;;
esac