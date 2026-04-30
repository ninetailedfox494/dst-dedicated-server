#!/usr/bin/env bash
set -euo pipefail

if grep -Eq 'match\([^,]+,[^,]+,[[:space:]]*[[:alpha:]_][[:alnum:]_]*[[:space:]]*\)' docker/entrypoint.sh; then
  echo "Expected entrypoint awk to avoid GNU-only match(..., ..., array) syntax"
  exit 1
fi

echo "PASS: entrypoint awk syntax is POSIX-compatible"
