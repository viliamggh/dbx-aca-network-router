# Lightweight Alpine Linux image for API-only connectivity testing
FROM --platform=linux/amd64 alpine:3.18

# Install system packages and build dependencies for Python and SQL connectivity
RUN apk add --no-cache \
    curl \
    bind-tools \
    netcat-openbsd \
    traceroute \
    iputils \
    python3 \
    py3-pip \
    bash \
    jq \
    g++ \
    gcc \
    musl-dev \
    python3-dev \
    unixodbc-dev \
    unixodbc \
    ca-certificates

# Create and activate virtual environment, then install Python packages
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install pyodbc requests flask

# Add venv to PATH
ENV PATH="/opt/venv/bin:$PATH"

# Install Microsoft ODBC Driver for SQL Server (AMD64 version)
RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.1.1-1_amd64.apk \
    && apk add --allow-untrusted msodbcsql17_17.10.1.1-1_amd64.apk \
    && rm msodbcsql17_17.10.1.1-1_amd64.apk

# Create app directory
WORKDIR /app

# Copy application files
COPY test_connectivity.py /app/
COPY test_endpoints.sh /app/
COPY test_api_server.py /app/
COPY startup.sh /app/

# Make scripts executable
RUN chmod +x /app/test_connectivity.py /app/test_endpoints.sh /app/test_api_server.py /app/startup.sh

# Create non-root user for security
RUN addgroup -g 1001 -S appuser && \
    adduser -S -D -H -u 1001 -h /app -s /sbin/nologin -G appuser appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 5000 for the API (will be mapped to 8080 by Container Apps)
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

STOPSIGNAL SIGTERM

CMD ["/app/startup.sh"]
