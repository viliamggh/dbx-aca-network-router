This folder contains a simple Nginx static site image intended to be built and pushed to ACR and consumed by the Azure Container App defined in `terraform/container_app.tf`.

Build locally:

```bash
# from repository root
docker build -t <ACR_LOGIN_SERVER>/<IMAGE_NAME>:<ENV> -f src/Dockerfile src
```

Example (if ACR login server is myacr.azurecr.io):

```bash
docker build -t myacr.azurecr.io/app:main -f src/Dockerfile src
```

Health check: GET /healthz returns 'ok'.
