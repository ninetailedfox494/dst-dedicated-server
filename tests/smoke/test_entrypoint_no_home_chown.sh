#!/usr/bin/env bash
set -euo pipefail

if grep -Eq '^[[:space:]]*chown[[:space:]]+-R[[:space:]]+dst:dst[[:space:]]+/home/dst[[:space:]]*$' docker/entrypoint.sh; then
  echo "Expected entrypoint to avoid broad /home/dst chown"
  exit 1
fi

echo "PASS: entrypoint avoids broad /home/dst chown"
