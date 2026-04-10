#!/usr/bin/env bash
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "SKIP: docker not available"
  exit 0
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
cat > "${TMP_DIR}/.env" <<'EOF'
DST_CLUSTER_TOKEN=pds-example-token
DST_CLUSTER_NAME=MyDediServer
EOF

if docker compose version >/dev/null 2>&1; then
  docker compose --env-file "${TMP_DIR}/.env" config > "${TMP_DIR}/cfg.yml"
elif command -v docker-compose >/dev/null 2>&1; then
  docker-compose --env-file "${TMP_DIR}/.env" config > "${TMP_DIR}/cfg.yml"
else
  echo "SKIP: no docker compose command found"
  exit 0
fi

grep -q "mod-updater:" "${TMP_DIR}/cfg.yml"
echo "PASS: compose includes mod-updater service"
