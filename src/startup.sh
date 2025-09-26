#!/bin/bash
"""
Startup script for Container App
Starts both Nginx and the test API server
"""

set -e

echo "Starting Container App with connectivity testing..."

# Start the API server in background
echo "Starting test API server..."
/opt/venv/bin/python /usr/local/bin/test_api_server.py &
API_PID=$!

# Wait a moment for API server to start
sleep 2

# Check if API server is running
if kill -0 $API_PID 2>/dev/null; then
    echo "✅ API server started successfully (PID: $API_PID)"
else
    echo "❌ Failed to start API server"
    exit 1
fi

# Start nginx in foreground
echo "Starting nginx..."
exec nginx -g "daemon off;"