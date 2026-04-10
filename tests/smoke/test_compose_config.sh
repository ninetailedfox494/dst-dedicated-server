#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

cat > "${TMP_DIR}/.env" <<'EOF'
DST_CLUSTER_TOKEN=pds-example-token
DST_CLUSTER_NAME=MyDediServer
EOF
if docker compose version >/dev/null 2>&1; then
  docker compose --env-file "${TMP_DIR}/.env" config >"${TMP_DIR}/compose.log"
elif command -v docker-compose >/dev/null 2>&1; then
  docker-compose --env-file "${TMP_DIR}/.env" config >"${TMP_DIR}/compose.log"
else
  echo "SKIP: no docker compose command found in this environment"
  exit 0
fi

grep -q "dst-master:" "${TMP_DIR}/compose.log"
grep -q "dst-caves:" "${TMP_DIR}/compose.log"
echo "PASS: compose defines both shard services"
