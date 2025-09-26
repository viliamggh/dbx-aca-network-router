#!/opt/venv/bin/python
"""
Network Router Test API - Optimized for programmatic access
Provides comprehensive REST endpoints for testing network and database connectivity
from within Azure Container App Environment
"""

import os
import sys
import subprocess
import json
import logging
from datetime import datetime
from flask import Flask, jsonify, request

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Service metadata
SERVICE_INFO = {
    'name': 'dbx-aca-network-router-api',
    'version': '2.0.0',
    'description': 'Network and database connectivity testing API for Azure Container Apps'
}

@app.route('/', methods=['GET'])
def root():
    """Root endpoint with service information and API documentation"""
    return jsonify({
        'service': SERVICE_INFO,
        'status': 'running',
        'endpoints': {
            'GET /': 'Service information and API docs',
            'GET /health': 'Simple health check',
            'GET /status': 'Detailed system status',
            'GET /tests/network': 'Network connectivity tests',
            'GET /tests/sql': 'SQL database connectivity tests', 
            'GET /tests/all': 'Run all tests sequentially',
            'POST /tests/custom': 'Execute custom network command',
            'GET /info/environment': 'Environment variables',
            'GET /info/config': 'Service configuration',
            'GET /info/network': 'Network interface information'
        },
        'usage': {
            'examples': [
                'curl http://your-aca-fqdn/',
                'curl http://your-aca-fqdn/tests/all',
                'curl -X POST http://your-aca-fqdn/tests/custom -H "Content-Type: application/json" -d \'{"command": "nslookup google.com"}\''
            ]
        },
        'timestamp': datetime.now().isoformat()
    })

@app.route('/health', methods=['GET'])
def health():
    """Simple health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': SERVICE_INFO['name'],
        'version': SERVICE_INFO['version'],
        'timestamp': datetime.now().isoformat()
    })

@app.route('/status', methods=['GET'])
def status():
    """Comprehensive system status check"""
    try:
        # System information
        hostname = subprocess.run(['hostname'], capture_output=True, text=True)
        uptime = subprocess.run(['cat', '/proc/uptime'], capture_output=True, text=True)
        
        # Network interface info
        ip_addr = subprocess.run(['hostname', '-I'], capture_output=True, text=True)
        
        status_data = {
            'status': 'healthy',
            'service': SERVICE_INFO,
            'system': {
                'hostname': hostname.stdout.strip() if hostname.returncode == 0 else 'unknown',
                'uptime_seconds': float(uptime.stdout.split()[0]) if uptime.returncode == 0 else None,
                'python_version': sys.version.split()[0],
                'platform': sys.platform,
                'container_ip': ip_addr.stdout.strip() if ip_addr.returncode == 0 else 'unknown'
            },
            'environment_check': {
                'has_azure_identity': bool(os.getenv('AZURE_CLIENT_ID')),
                'has_sql_config': bool(os.getenv('SQL_SERVER_1_HOSTNAME')),
                'has_keyvault_config': bool(os.getenv('KEY_VAULT_NAME')),
                'managed_identity_endpoint': bool(os.getenv('IDENTITY_ENDPOINT'))
            },
            'test_scripts': {
                'network_script_exists': os.path.exists('/app/test_endpoints.sh'),
                'sql_script_exists': os.path.exists('/app/test_connectivity.py')
            },
            'timestamp': datetime.now().isoformat()
        }
        
        return jsonify(status_data)
        
    except Exception as e:
        logger.error(f"Status check failed: {e}")
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/tests/network', methods=['GET'])
def test_network():
    """Execute network connectivity tests"""
    try:
        logger.info("Executing network connectivity tests")
        
        result = subprocess.run(
            ['/bin/bash', '/app/test_endpoints.sh'],
            capture_output=True,
            text=True,
            timeout=90,
            cwd='/app'
        )
        
        response_data = {
            'test_type': 'network_connectivity',
            'status': 'passed' if result.returncode == 0 else 'failed',
            'exit_code': result.returncode,
            'duration': '90s max',
            'output': result.stdout,
            'errors': result.stderr if result.stderr else None,
            'timestamp': datetime.now().isoformat()
        }
        
        # Log summary
        logger.info(f"Network tests completed: status={response_data['status']}, exit_code={result.returncode}")
        
        return jsonify(response_data)
        
    except subprocess.TimeoutExpired:
        logger.warning("Network tests timed out after 90 seconds")
        return jsonify({
            'test_type': 'network_connectivity',
            'status': 'timeout',
            'error': 'Tests timed out after 90 seconds',
            'timestamp': datetime.now().isoformat()
        }), 408
        
    except Exception as e:
        logger.error(f"Network tests failed with exception: {e}")
        return jsonify({
            'test_type': 'network_connectivity',
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/tests/sql', methods=['GET'])
def test_sql():
    """Execute SQL database connectivity tests"""
    try:
        logger.info("Executing SQL connectivity tests")
        
        result = subprocess.run(
            ['/opt/venv/bin/python', '/app/test_connectivity.py'],
            capture_output=True,
            text=True,
            timeout=180,
            cwd='/app'
        )
        
        # Try to parse JSON output from SQL test script
        sql_data = None
        if result.stdout.strip():
            try:
                sql_data = json.loads(result.stdout)
            except json.JSONDecodeError:
                logger.warning("SQL test output is not valid JSON")
        
        response_data = {
            'test_type': 'sql_connectivity',
            'status': 'passed' if result.returncode == 0 else 'failed',
            'exit_code': result.returncode,
            'duration': '180s max',
            'structured_results': sql_data,
            'raw_output': result.stdout if not sql_data else None,
            'errors': result.stderr if result.stderr else None,
            'timestamp': datetime.now().isoformat()
        }
        
        # Log summary
        logger.info(f"SQL tests completed: status={response_data['status']}, exit_code={result.returncode}")
        
        return jsonify(response_data)
        
    except subprocess.TimeoutExpired:
        logger.warning("SQL tests timed out after 180 seconds")
        return jsonify({
            'test_type': 'sql_connectivity',
            'status': 'timeout',
            'error': 'Tests timed out after 180 seconds',
            'timestamp': datetime.now().isoformat()
        }), 408
        
    except Exception as e:
        logger.error(f"SQL tests failed with exception: {e}")
        return jsonify({
            'test_type': 'sql_connectivity',
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/tests/all', methods=['GET'])
def test_all():
    """Execute all tests sequentially and return comprehensive results"""
    try:
        logger.info("Starting comprehensive test suite")
        
        test_results = {
            'test_suite': 'comprehensive',
            'started_at': datetime.now().isoformat(),
            'tests': {},
            'summary': {}
        }
        
        # Execute network tests
        logger.info("Running network tests...")
        try:
            net_result = subprocess.run(
                ['/bin/bash', '/app/test_endpoints.sh'],
                capture_output=True, text=True, timeout=90, cwd='/app'
            )
            test_results['tests']['network'] = {
                'status': 'passed' if net_result.returncode == 0 else 'failed',
                'exit_code': net_result.returncode,
                'output': net_result.stdout,
                'errors': net_result.stderr if net_result.stderr else None
            }
        except subprocess.TimeoutExpired:
            test_results['tests']['network'] = {
                'status': 'timeout',
                'error': 'Network tests timed out after 90 seconds'
            }
        except Exception as e:
            test_results['tests']['network'] = {
                'status': 'error',
                'error': str(e)
            }
        
        # Execute SQL tests
        logger.info("Running SQL tests...")
        try:
            sql_result = subprocess.run(
                ['/opt/venv/bin/python', '/app/test_connectivity.py'],
                capture_output=True, text=True, timeout=180, cwd='/app'
            )
            
            # Parse JSON if available
            sql_data = None
            if sql_result.stdout.strip():
                try:
                    sql_data = json.loads(sql_result.stdout)
                except json.JSONDecodeError:
                    pass
            
            test_results['tests']['sql'] = {
                'status': 'passed' if sql_result.returncode == 0 else 'failed',
                'exit_code': sql_result.returncode,
                'structured_results': sql_data,
                'raw_output': sql_result.stdout if not sql_data else None,
                'errors': sql_result.stderr if sql_result.stderr else None
            }
        except subprocess.TimeoutExpired:
            test_results['tests']['sql'] = {
                'status': 'timeout',
                'error': 'SQL tests timed out after 180 seconds'
            }
        except Exception as e:
            test_results['tests']['sql'] = {
                'status': 'error',
                'error': str(e)
            }
        
        # Generate summary
        test_results['completed_at'] = datetime.now().isoformat()
        
        statuses = [test.get('status') for test in test_results['tests'].values()]
        passed_count = statuses.count('passed')
        failed_count = statuses.count('failed')
        error_count = statuses.count('error') + statuses.count('timeout')
        
        test_results['summary'] = {
            'total_tests': len(test_results['tests']),
            'passed': passed_count,
            'failed': failed_count,
            'errors': error_count,
            'overall_status': 'passed' if passed_count == len(test_results['tests']) else 
                            'partial' if passed_count > 0 else 'failed'
        }
        
        logger.info(f"Test suite completed: {test_results['summary']['overall_status']}")
        return jsonify(test_results)
        
    except Exception as e:
        logger.error(f"Test suite failed: {e}")
        return jsonify({
            'test_suite': 'comprehensive',
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/tests/custom', methods=['POST'])
def test_custom():
    """Execute custom network command with security restrictions"""
    try:
        if not request.is_json:
            return jsonify({
                'error': 'Request must be JSON',
                'content_type_received': request.content_type,
                'example': {'command': 'nslookup google.com'}
            }), 400
        
        data = request.get_json()
        if not data or 'command' not in data:
            return jsonify({
                'error': 'Missing "command" field in request body',
                'example': {'command': 'nslookup google.com'}
            }), 400
        
        command = data['command'].strip()
        timeout = min(data.get('timeout', 30), 120)  # Max 2 minutes
        
        logger.info(f"Custom command request: {command}")
        
        # Security whitelist
        allowed_commands = {
            'nslookup', 'dig', 'ping', 'curl', 'nc', 'netcat', 'telnet',
            'traceroute', 'ss', 'netstat', 'ip', 'hostname', 'whoami',
            'id', 'env', 'cat', 'ls', 'pwd', 'date', 'uptime'
        }
        
        command_parts = command.split()
        if not command_parts:
            return jsonify({
                'error': 'Empty command',
                'allowed_commands': sorted(allowed_commands)
            }), 400
        
        base_command = command_parts[0]
        if base_command not in allowed_commands:
            return jsonify({
                'error': f'Command "{base_command}" not allowed',
                'allowed_commands': sorted(allowed_commands)
            }), 403
        
        # Execute command
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd='/app'
        )
        
        response_data = {
            'command': command,
            'status': 'completed',
            'exit_code': result.returncode,
            'success': result.returncode == 0,
            'output': result.stdout,
            'errors': result.stderr if result.stderr else None,
            'timeout_used': timeout,
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"Custom command completed: {command} (exit_code={result.returncode})")
        return jsonify(response_data)
        
    except subprocess.TimeoutExpired:
        logger.warning(f"Custom command timed out: {command}")
        return jsonify({
            'command': command,
            'status': 'timeout',
            'error': f'Command timed out after {timeout} seconds',
            'timestamp': datetime.now().isoformat()
        }), 408
        
    except Exception as e:
        logger.error(f"Custom command failed: {e}")
        return jsonify({
            'command': data.get('command', 'unknown') if 'data' in locals() else 'unknown',
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/info/environment', methods=['GET'])
def get_environment():
    """Get filtered environment variables"""
    env_data = {
        'azure_identity': {
            'client_id': os.getenv('AZURE_CLIENT_ID'),
            'tenant_id': os.getenv('AZURE_TENANT_ID'),
            'identity_endpoint_available': bool(os.getenv('IDENTITY_ENDPOINT')),
            'identity_header_available': bool(os.getenv('IDENTITY_HEADER'))
        },
        'sql_configuration': {
            'server_1_hostname': os.getenv('SQL_SERVER_1_HOSTNAME'),
            'server_2_hostname': os.getenv('SQL_SERVER_2_HOSTNAME'),
            'database_1_name': os.getenv('SQL_DATABASE_1_NAME'),
            'database_2_name': os.getenv('SQL_DATABASE_2_NAME'),
            'admin_username': os.getenv('SQL_ADMIN_USERNAME')
        },
        'key_vault': {
            'name': os.getenv('KEY_VAULT_NAME')
        },
        'container_info': {
            'hostname': os.getenv('HOSTNAME'),
            'website_hostname': os.getenv('WEBSITE_HOSTNAME'),  # Container Apps specific
            'container_app_name': os.getenv('CONTAINER_APP_NAME')
        }
    }
    
    return jsonify({
        'environment': env_data,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/info/config', methods=['GET'])
def get_config():
    """Get service configuration details"""
    return jsonify({
        'service': SERVICE_INFO,
        'flask_config': {
            'debug': app.debug,
            'testing': app.testing
        },
        'runtime': {
            'python_version': sys.version,
            'working_directory': os.getcwd(),
            'script_location': __file__
        },
        'timestamp': datetime.now().isoformat()
    })

@app.route('/info/network', methods=['GET'])
def get_network_info():
    """Get network interface information"""
    try:
        # Get network interface info
        ip_info = subprocess.run(['ip', 'addr', 'show'], capture_output=True, text=True)
        route_info = subprocess.run(['ip', 'route'], capture_output=True, text=True)
        dns_info = subprocess.run(['cat', '/etc/resolv.conf'], capture_output=True, text=True)
        
        return jsonify({
            'network_interfaces': ip_info.stdout if ip_info.returncode == 0 else 'unavailable',
            'routing_table': route_info.stdout if route_info.returncode == 0 else 'unavailable',
            'dns_configuration': dns_info.stdout if dns_info.returncode == 0 else 'unavailable',
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'error': f'Failed to get network info: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        'error': 'Endpoint not found',
        'message': 'The requested endpoint does not exist',
        'available_endpoints': [rule.rule for rule in app.url_map.iter_rules()],
        'timestamp': datetime.now().isoformat()
    }), 404

@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({
        'error': 'Method not allowed',
        'message': f'The method {request.method} is not allowed for this endpoint',
        'timestamp': datetime.now().isoformat()
    }), 405

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {error}")
    return jsonify({
        'error': 'Internal server error',
        'message': 'An unexpected error occurred',
        'timestamp': datetime.now().isoformat()
    }), 500

if __name__ == '__main__':
    logger.info(f"Starting {SERVICE_INFO['name']} v{SERVICE_INFO['version']}")
    logger.info("Server will be accessible on all interfaces at port 5000")
    
    # Run Flask app
    app.run(
        host='0.0.0.0', 
        port=5000, 
        debug=False,
        threaded=True
    )