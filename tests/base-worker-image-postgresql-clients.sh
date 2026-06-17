#!/usr/bin/env sh
set -eu

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
dockerfile_path="$repo_root/images/base/Dockerfile"

assert_dockerfile_contains() {
  expected="$1"

  if ! grep -Fq "$expected" "$dockerfile_path"; then
    echo "Expected Dockerfile content not found: $expected" >&2
    exit 1
  fi
}

assert_dockerfile_contains "https://apt.postgresql.org/pub/repos/apt"
assert_dockerfile_contains "https://www.postgresql.org/media/keys/ACCC4CF8.asc"

for version in 16 17 18; do
  assert_dockerfile_contains "postgresql-client-$version"

  for command in psql pg_dump pg_dumpall; do
    assert_dockerfile_contains "/usr/lib/postgresql/$version/bin/$command"
  done
done
