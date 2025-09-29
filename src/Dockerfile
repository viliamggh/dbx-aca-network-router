# FROM python:3.11-slim
# WORKDIR /app
# COPY tcp_proxy.py .
# EXPOSE 1433
# CMD ["python", "tcp_proxy.py"]

# FROM envoyproxy/envoy:v1.31-latest
# COPY envoy.yaml /etc/envoy/envoy.yaml
# CMD ["/usr/local/bin/envoy", "-c", "/etc/envoy/envoy.yaml", "-l", "info", "--base-id", "1"]

FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/nginx.conf