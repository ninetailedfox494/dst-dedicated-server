#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

PROJECT_ROOT="${TMP_DIR}/project"
mkdir -p "${PROJECT_ROOT}/data/cluster" "${PROJECT_ROOT}/data/master" "${PROJECT_ROOT}/data/caves"

cat > "${PROJECT_ROOT}/data/cluster/test_cluster.txt" <<'EOF'
cluster-old
EOF
cat > "${PROJECT_ROOT}/data/master/test_master.txt" <<'EOF'
master-old
EOF
cat > "${PROJECT_ROOT}/data/caves/test_caves.txt" <<'EOF'
caves-old
EOF

WORLD_SNAPSHOT_SKIP_COMPOSE=1 \
WORLD_SNAPSHOT_PROJECT_ROOT="${PROJECT_ROOT}" \
bash scripts/world_snapshot.sh backup world-before-reset >/dev/null

ARCHIVE="$(ls -1 "${PROJECT_ROOT}"/data/backups/world-before-reset-*.tar.gz | head -n 1)"
[[ -f "${ARCHIVE}" ]]

cat > "${PROJECT_ROOT}/data/master/test_master.txt" <<'EOF'
master-new
EOF

WORLD_SNAPSHOT_SKIP_COMPOSE=1 \
WORLD_SNAPSHOT_PROJECT_ROOT="${PROJECT_ROOT}" \
bash scripts/world_snapshot.sh restore world-before-reset >/dev/null

grep -q "master-old" "${PROJECT_ROOT}/data/master/test_master.txt"
echo "PASS: world snapshot backup/restore works"
