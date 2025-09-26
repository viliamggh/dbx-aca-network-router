# Nginx based image with SQL Server connectivity testing capabilities
FROM nginx:stable-alpine

# Install SQL Server tools and utilities for connectivity testing
RUN apk add --no-cache \
    curl \
    bind-tools \
    netcat-openbsd \
    python3 \
    py3-pip \
    bash \
    jq \
    && pip3 install pyodbc requests flask werkzeug

# Install Microsoft ODBC Driver for SQL Server
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
