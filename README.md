# prefect-worker

## Images

Build the base image first:

```sh
docker build -t prefect-worker-base:latest -f images/base/Dockerfile .
```

Build the process worker image:

```sh
docker build -t prefect-process-worker:latest -f images/process/Dockerfile .
```

## Compose

Use the built image and mount the host Docker socket:

```yaml
prefect-process-worker:
  image: "prefect-process-worker:latest"
  restart: unless-stopped
  container_name: prefect-process-worker
  networks:
    - minipc
  depends_on:
    prefect-server:
      condition: service_healthy
  environment:
    PREFECT_API_URL: "http://prefect-server:4200/api"
  volumes:
    - /opt/prefect:/app
    - /var/run/docker.sock:/var/run/docker.sock
  working_dir: /app/flows
  command: sh -c "uv sync --frozen --no-dev && . .venv/bin/activate && prefect worker start --pool process-pool --type process"
```
