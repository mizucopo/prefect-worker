#!/usr/bin/env bash
set -euo pipefail

cat <<EOF
## Worker Images

この GitHub Release に対応する Worker Image です。

- Base Worker Image: \`${BASE_IMAGE}\`
- Process Worker Image: \`${PROCESS_IMAGE}\`

Docker Hub: ${DOCKERHUB_URL}
EOF
