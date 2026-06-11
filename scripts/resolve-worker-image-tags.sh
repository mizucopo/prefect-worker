#!/usr/bin/env bash
set -euo pipefail

prefect_image_tag_raw="$(cat version)"
revision_raw="$(cat revision)"

case "${prefect_image_tag_raw}" in
  *$'\n'*)
    echo "version must contain exactly one line." >&2
    exit 1
    ;;
esac

case "${revision_raw}" in
  *$'\n'*)
    echo "revision must contain at most one line." >&2
    exit 1
    ;;
esac

prefect_image_tag="$(printf '%s' "${prefect_image_tag_raw}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
revision="$(printf '%s' "${revision_raw}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

if [ -z "${prefect_image_tag}" ]; then
  echo "version must not be empty." >&2
  exit 1
fi

if [[ "${prefect_image_tag}" == prefect-* ]]; then
  echo "version must contain the Upstream Prefect Image Tag without a prefect- prefix." >&2
  exit 1
fi

if [[ ! "${prefect_image_tag}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
  echo "version contains characters that are not valid for this release tag." >&2
  exit 1
fi

if [ -n "${revision}" ] && [[ ! "${revision}" =~ ^r[0-9]+$ ]]; then
  echo "revision must be empty or match r[0-9]+." >&2
  exit 1
fi

release_tag="${prefect_image_tag}"
base_image_tag="${prefect_image_tag}-base"
process_image_tag="${prefect_image_tag}-process"

if [ -n "${revision}" ]; then
  release_tag="${release_tag}-${revision}"
  base_image_tag="${base_image_tag}-${revision}"
  process_image_tag="${process_image_tag}-${revision}"
fi

{
  echo "prefect_image_tag=${prefect_image_tag}"
  echo "revision=${revision}"
  echo "release_tag=${release_tag}"
  echo "base_image_tag=${base_image_tag}"
  echo "process_image_tag=${process_image_tag}"
  echo "base_image=${IMAGE_REPOSITORY}:${base_image_tag}"
  echo "process_image=${IMAGE_REPOSITORY}:${process_image_tag}"
} >> "${GITHUB_OUTPUT}"
