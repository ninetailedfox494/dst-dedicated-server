#!/usr/bin/env bash
set -euo pipefail

grep -q "./env:/home/dst/docker/env:ro" docker/docker-compose.yml
grep -q 'RUNTIME_ENV_FILE="${DST_RUNTIME_ENV_FILE:-/home/dst/docker/env/.env}"' docker/entrypoint.sh
grep -q 'load_runtime_env_file "${RUNTIME_ENV_FILE}"' docker/entrypoint.sh

echo "PASS: runtime env reload wiring is present"
