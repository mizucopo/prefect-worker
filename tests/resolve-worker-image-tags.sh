#!/usr/bin/env sh
set -eu

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_case() {
  version_value="$1"
  revision_value="$2"

  printf '%s\n' "$version_value" > "$tmp_dir/version"
  printf '%s' "$revision_value" > "$tmp_dir/revision"

  (
    cd "$tmp_dir"
    IMAGE_REPOSITORY=mizucopo/prefect-flows \
      GITHUB_OUTPUT="$tmp_dir/output" \
      bash "$repo_root/scripts/resolve-worker-image-tags.sh"
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
run_case "3.7.4-python3.14" ""
assert_output_contains "release_tag=3.7.4-python3.14"
assert_output_contains "base_image_tag=3.7.4-python3.14-base"
assert_output_contains "process_image_tag=3.7.4-python3.14-process"
assert_output_contains "base_image=mizucopo/prefect-flows:3.7.4-python3.14-base"
assert_output_contains "process_image=mizucopo/prefect-flows:3.7.4-python3.14-process"

: > "$tmp_dir/output"
run_case "3.7.4-python3.14" "r1"
assert_output_contains "release_tag=3.7.4-python3.14-r1"
assert_output_contains "base_image_tag=3.7.4-python3.14-base-r1"
assert_output_contains "process_image_tag=3.7.4-python3.14-process-r1"

printf 'prefect-3.7.4-python3.14\n' > "$tmp_dir/version"
: > "$tmp_dir/revision"
if (
  cd "$tmp_dir"
  IMAGE_REPOSITORY=mizucopo/prefect-flows \
    GITHUB_OUTPUT="$tmp_dir/output" \
    bash "$repo_root/scripts/resolve-worker-image-tags.sh"
) 2> "$tmp_dir/error"; then
  echo "Expected prefect-prefixed version to fail." >&2
  exit 1
fi

if ! grep -Fqx "version must contain the Upstream Prefect Image Tag without a prefect- prefix." "$tmp_dir/error"; then
  echo "Expected prefect-prefixed version error was not found." >&2
  cat "$tmp_dir/error" >&2
  exit 1
fi
