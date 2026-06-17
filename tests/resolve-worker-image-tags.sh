#!/usr/bin/env sh
set -eu

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
script_path="$repo_root/scripts/resolve-worker-image-tags.sh"
image_repository="mizucopo/prefect-flows"
version_tag="3.7.4-python3.14"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_case() {
  version_value="$1"
  revision_value="$2"

  printf '%s\n' "$version_value" > "$tmp_dir/version"
  printf '%s' "$revision_value" > "$tmp_dir/revision"

  (
    cd "$tmp_dir"
    IMAGE_REPOSITORY="$image_repository" \
      GITHUB_OUTPUT="$tmp_dir/output" \
      bash "$script_path"
  )
}

assert_output_contains() {
  expected="$1"

  if ! grep -Fqx "$expected" "$tmp_dir/output"; then
    echo "Expected output line not found: $expected" >&2
    echo "Actual output:" >&2
    cat "$tmp_dir/output" >&2
    exit 1
  fi
}

: > "$tmp_dir/output"
run_case "$version_tag" ""
assert_output_contains "release_tag=$version_tag"
assert_output_contains "base_image_tag=$version_tag-base"
assert_output_contains "process_image_tag=$version_tag-process"
assert_output_contains "base_image=$image_repository:$version_tag-base"
assert_output_contains "process_image=$image_repository:$version_tag-process"

: > "$tmp_dir/output"
run_case "$version_tag" "r1"
assert_output_contains "release_tag=$version_tag-r1"
assert_output_contains "base_image_tag=$version_tag-base-r1"
assert_output_contains "process_image_tag=$version_tag-process-r1"

printf 'prefect-%s\n' "$version_tag" > "$tmp_dir/version"
: > "$tmp_dir/revision"
if (
  cd "$tmp_dir"
  IMAGE_REPOSITORY="$image_repository" \
    GITHUB_OUTPUT="$tmp_dir/output" \
    bash "$script_path"
) 2> "$tmp_dir/error"; then
  echo "Expected prefect-prefixed version to fail." >&2
  exit 1
fi

if ! grep -Fqx "version must contain the Upstream Prefect Image Tag without a prefect- prefix." "$tmp_dir/error"; then
  echo "Expected prefect-prefixed version error was not found." >&2
  cat "$tmp_dir/error" >&2
  exit 1
fi
