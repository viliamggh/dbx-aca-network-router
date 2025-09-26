#!/opt/venv/bin/python
"""
Simple test API server for Container App connectivity testing
Provides REST endpoints to execute network and SQL connectivity tests
"""

import os
import subprocess
import json
import threading
import time
from flask import Flask, jsonify, request
from werkzeug.serving import make_server

app = Flask(__name__)

@app.route('/api/health')
def health():
    """Health check endpoint"""
    return {'status': 'ok', 'timestamp': time.time()}

@app.route('/api/test/network')
def test_network():
    """Run network connectivity tests"""
    try:
        result = subprocess.run(
            ['/usr/local/bin/test_endpoints.sh'],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        return {
            'success': result.returncode == 0,
            'returncode': result.returncode,
            'stdout': result.stdout,
            'stderr': result.stderr,
            'timestamp': time.time()
        }
    except subprocess.TimeoutExpired:
        return {'error': 'Network test timed out'}, 408
    except Exception as e:
        return {'error': str(e)}, 500

@app.route('/api/test/sql')
def test_sql():
    """Run SQL connectivity tests"""
    try:
        result = subprocess.run(
            ['/opt/venv/bin/python', '/usr/local/bin/test_connectivity.py'],
            capture_output=True,
            text=True,
            timeout=60
        )
        
        # Try to parse JSON output from the test script
        try:
            sql_results = json.loads(result.stdout)
        except:
            sql_results = {
                'raw_output': result.stdout,
                'stderr': result.stderr
            }
        
        return {
            'success': result.returncode == 0,
            'returncode': result.returncode,
            'results': sql_results,
            'stderr': result.stderr,
            'timestamp': time.time()
        }
    except subprocess.TimeoutExpired:
        return {'error': 'SQL test timed out'}, 408
    except Exception as e:
        return {'error': str(e)}, 500

@app.route('/api/test/command')
def test_command():
    """Run custom command (with security restrictions)"""
    cmd = request.args.get('cmd', '').strip()
    if not cmd:
        return {'error': 'No command specified'}, 400
    
    # Security: Allow only safe commands
    allowed_commands = ['nslookup', 'ping', 'nc', 'curl', 'dig', 'host', 'env']
    cmd_parts = cmd.split()
    if not cmd_parts or cmd_parts[0] not in allowed_commands:
        return {'error': f'Command not allowed. Allowed: {allowed_commands}'}, 403
    
    try:
        result = subprocess.run(
            cmd_parts,
            capture_output=True,
            text=True,
            timeout=30
        )
        
        return {
            'command': cmd,
            'success': result.returncode == 0,
            'returncode': result.returncode,
            'stdout': result.stdout,
            'stderr': result.stderr,
            'timestamp': time.time()
        }
    except subprocess.TimeoutExpired:
        return {'error': 'Command timed out'}, 408
    except Exception as e:
        return {'error': str(e)}, 500

@app.route('/api/environment')
def get_environment():
    """Get environment variables (filtered)"""
    env_vars = {}
    for key, value in os.environ.items():
        # Only include relevant environment variables
        if any(prefix in key for prefix in ['SQL_', 'KEY_VAULT', 'AZURE_', 'HOSTNAME']):
            env_vars[key] = value
    
    # Add network information
    try:
        ip_result = subprocess.run(['hostname', '-i'], capture_output=True, text=True)
        env_vars['CONTAINER_IP'] = ip_result.stdout.strip()
    except:
        pass
    
    return {
        'environment': env_vars,
        'timestamp': time.time()
    }

def run_api_server():
    """Run the API server in a separate thread"""
    server = make_server('127.0.0.1', 5000, app)
    server.serve_forever()

if __name__ == '__main__':
    # Start API server in background
    api_thread = threading.Thread(target=run_api_server, daemon=True)
    api_thread.start()
    
    print("Test API server started on http://127.0.0.1:5000")
    print("Available endpoints:")
    print("  GET /api/health - Health check")
    print("  GET /api/test/network - Network connectivity tests")
    print("  GET /api/test/sql - SQL database connectivity tests")
    print("  GET /api/test/command?cmd=<command> - Run custom command")
    print("  GET /api/environment - Show environment variables")
    
    # Keep the main thread alive
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Shutting down...")