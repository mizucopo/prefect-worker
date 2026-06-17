# check=skip=InvalidDefaultArgInFrom
ARG PREFECT_IMAGE_TAG
FROM prefecthq/prefect:${PREFECT_IMAGE_TAG}

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gzip \
    && install -d /usr/share/postgresql-common/pgdg \
    && curl -fsSL -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && . /etc/os-release \
    && printf '%s\n' \
        'Types: deb' \
        'URIs: https://apt.postgresql.org/pub/repos/apt' \
        "Suites: ${VERSION_CODENAME}-pgdg" \
        "Architectures: $(dpkg --print-architecture)" \
        'Components: main' \
        'Signed-By: /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc' \
        > /etc/apt/sources.list.d/pgdg.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client-16 \
        postgresql-client-17 \
        postgresql-client-18 \
    && command -v gzip >/dev/null \
    && test -x /usr/lib/postgresql/16/bin/psql \
    && test -x /usr/lib/postgresql/16/bin/pg_dump \
    && test -x /usr/lib/postgresql/16/bin/pg_dumpall \
    && test -x /usr/lib/postgresql/17/bin/psql \
    && test -x /usr/lib/postgresql/17/bin/pg_dump \
    && test -x /usr/lib/postgresql/17/bin/pg_dumpall \
    && test -x /usr/lib/postgresql/18/bin/psql \
    && test -x /usr/lib/postgresql/18/bin/pg_dump \
    && test -x /usr/lib/postgresql/18/bin/pg_dumpall \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*
