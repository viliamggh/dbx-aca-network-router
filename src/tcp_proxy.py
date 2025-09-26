import socket
import threading
import logging
import os

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# SQL Server mapping by database name
SQL_SERVERS = {
    "database1": "10.0.2.4",  # SQL Server 1 
    "database2": "10.0.2.5"   # SQL Server 2 
}

def parse_connection_request(data):
    """Parse JDBC connection to determine target database"""
    try:
        # Look for database name in TDS connection string
        data_str = data.decode('utf-8', errors='ignore').lower()
        
        if 'database=database2' in data_str or 'database2' in data_str:
            return "database2"
        else:
            return "database1"  # Default to database1
    except:
        return "database1"  # Fallback to database1

def handle_client(client_socket):
    """Handle JDBC connection and route to specific SQL server"""
    server_socket = None
    
    try:
        # Peek at initial connection data to determine target database
        client_socket.settimeout(5.0)  # 5 second timeout for initial data
        initial_data = client_socket.recv(1024, socket.MSG_PEEK)
        
        # Determine target database from connection string
        target_db = parse_connection_request(initial_data)
        server_host = SQL_SERVERS[target_db]
        
        # Connect to target SQL server
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server_socket.connect((server_host, 1433))
        client_socket.settimeout(None)  # Remove timeout
        
        logger.info(f"JDBC connection routed to {target_db} ({server_host})")
        
        # Bidirectional data transfer
        c2s = threading.Thread(target=transfer_data, args=(client_socket, server_socket))
        s2c = threading.Thread(target=transfer_data, args=(server_socket, client_socket))
        
        c2s.start()
        s2c.start()
        c2s.join()
        s2c.join()
        
    except Exception as e:
        logger.error(f"Proxy error: {e}")
    finally:
        if server_socket:
            server_socket.close()
        client_socket.close()

def transfer_data(source, destination):
    """Transfer data between sockets"""
    try:
        while True:
            data = source.recv(4096)
            if not data:
                break
            destination.sendall(data)
    except:
        pass

if __name__ == '__main__':
    proxy_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    proxy_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    proxy_socket.bind(('0.0.0.0', 1433))
    proxy_socket.listen(10)
    
    logger.info("Minimal JDBC proxy listening on :1433")
    
    while True:
        try:
            client_socket, addr = proxy_socket.accept()
            threading.Thread(target=handle_client, args=(client_socket,), daemon=True).start()
        except Exception as e:
            logger.error(f"Accept error: {e}")