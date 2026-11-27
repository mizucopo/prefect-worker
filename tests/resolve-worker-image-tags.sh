#!/usr/bin/env sh
set -eu

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
script_path="$repo_root/scripts/resolve-worker-image-tags.sh"
image_repository="mizucopo/prefect-worker"
version_tag="3.8.1-python3.14"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' 0

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

assert_case_fails() {
  : > "$tmp_dir/output"
  if run_case "$1" "$2" 2> "$tmp_dir/error"; then
    echo "Expected tag resolution to fail." >&2
    exit 1
  fi
  if [ -s "$tmp_dir/output" ]; then
    echo "Tag resolution wrote output on failure." >&2
    cat "$tmp_dir/output" >&2
    exit 1
  fi

  shift 2
  printf '%s\n' "$@" > "$tmp_dir/expected_error"
  diff -u "$tmp_dir/expected_error" "$tmp_dir/error"
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

assert_case_fails "prefect-$version_tag" "" \
  "version must contain the Upstream Prefect Image Tag without a prefect- prefix."

# A 120-character version produces a 128-character tag with the -process suffix.
long_version_tag="$(printf '%0120d' 0)"
run_case "$long_version_tag" ""
assert_output_contains "process_image_tag=$long_version_tag-process"

assert_case_fails "${long_version_tag}0" "" \
  "process_image_tag exceeds 128 characters (129)."

# With -r1, the base tag is 128 characters and only the process tag is too long.
assert_case_fails "$long_version_tag" "r1" \
  "process_image_tag exceeds 128 characters (131)."

assert_case_fails "${long_version_tag}0" "r1" \
  "base_image_tag exceeds 128 characters (129)." \
  "process_image_tag exceeds 128 characters (132)."
