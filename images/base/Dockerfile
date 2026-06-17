# check=skip=InvalidDefaultArgInFrom
ARG PREFECT_IMAGE_TAG
FROM prefecthq/prefect:${PREFECT_IMAGE_TAG}

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends gzip \
    && command -v gzip >/dev/null \
    && rm -rf /var/lib/apt/lists/*
