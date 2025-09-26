FROM python:3.11-slim
WORKDIR /app
COPY tcp_proxy.py .
EXPOSE 1433
CMD ["python", "tcp_proxy.py"]