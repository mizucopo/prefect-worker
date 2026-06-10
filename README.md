# prefect-worker

## Images

The `version` file stores the upstream Prefect image tag used for the base image.

Worker images are published to Docker Hub under `mizucopo/prefect-flows`.
Image tags include the upstream Prefect image tag first, followed by the worker image variant.
Do not publish `latest` tags.

Set the image tag variables:

```sh
IMAGE_REPOSITORY="mizucopo/prefect-flows"
PREFECT_IMAGE_TAG="$(cat version)"
REVISION=""
```

For a corrected republish of the same upstream Prefect image tag and worker image variant, set `REVISION` manually before calculating the image tags:

```sh
REVISION="r1"
```

Calculate the image tags:

```sh
BASE_IMAGE_TAG="prefect-${PREFECT_IMAGE_TAG}-base${REVISION:+-${REVISION}}"
PROCESS_IMAGE_TAG="prefect-${PREFECT_IMAGE_TAG}-process${REVISION:+-${REVISION}}"
```

Build the base image first:

```sh
docker build \
  --build-arg PREFECT_IMAGE_TAG="${PREFECT_IMAGE_TAG}" \
  -t "${IMAGE_REPOSITORY}:${BASE_IMAGE_TAG}" \
  -f images/base/Dockerfile .
```

Push the base image:

```sh
docker push "${IMAGE_REPOSITORY}:${BASE_IMAGE_TAG}"
```

Build the process worker image from the published base image:

```sh
docker build \
  --build-arg BASE_IMAGE="${IMAGE_REPOSITORY}:${BASE_IMAGE_TAG}" \
  -t "${IMAGE_REPOSITORY}:${PROCESS_IMAGE_TAG}" \
  -f images/process/Dockerfile .
```

Push the process worker image:

```sh
docker push "${IMAGE_REPOSITORY}:${PROCESS_IMAGE_TAG}"
```

## Compose

Use the published process worker image and mount the host Docker socket:

```yaml
prefect-process-worker:
  image: "mizucopo/prefect-flows:prefect-3.7.3-python3.14-process"
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

## Architecture Decisions

- [Worker image tags](docs/adr/0001-worker-image-tags.md)
