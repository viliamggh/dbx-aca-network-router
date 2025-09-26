# Nginx based image with SQL Server connectivity testing capabilities
FROM --platform=linux/amd64 nginx:stable-alpine

# Install system packages and build dependencies
RUN apk add --no-cache \
    curl \
    bind-tools \
    netcat-openbsd \
    python3 \
    py3-pip \
    bash \
    jq \
    g++ \
    gcc \
    musl-dev \
    python3-dev \
    unixodbc-dev \
    unixodbc

# Create and activate virtual environment, then install Python packages
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install pyodbc requests flask werkzeug

# Add venv to PATH
ENV PATH="/opt/venv/bin:$PATH"

# Install Microsoft ODBC Driver for SQL Server (AMD64 version)
RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.1.1-1_amd64.apk \
    && apk add --allow-untrusted msodbcsql17_17.10.1.1-1_amd64.apk \
    && rm msodbcsql17_17.10.1.1-1_amd64.apk

# Remove default configuration and add our custom one (listens on 8080)
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static site into nginx html root
COPY www /usr/share/nginx/html

# Copy testing scripts and startup script
COPY test_connectivity.py /usr/local/bin/
COPY test_endpoints.sh /usr/local/bin/
COPY test_api_server.py /usr/local/bin/
COPY startup.sh /usr/local/bin/

# Make scripts executable
RUN chmod +x /usr/local/bin/test_connectivity.py /usr/local/bin/test_endpoints.sh /usr/local/bin/test_api_server.py /usr/local/bin/startup.sh

# Expose the port expected by the Terraform container app (target_port = 8080)
EXPOSE 8080

STOPSIGNAL SIGTERM

CMD ["/usr/local/bin/startup.sh"]
