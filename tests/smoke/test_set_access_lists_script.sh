#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/env" "${TMP_DIR}/data/cluster"
cat > "${TMP_DIR}/env/admins.txt" <<'EOF'
KU_J9MSQD54
EOF
cat > "${TMP_DIR}/env/whitelist.txt" <<'EOF'
KU_0PX1vpn8
EOF
cat > "${TMP_DIR}/env/blocklist.txt" <<'EOF'
KU_BLOCK12345
EOF

set +e
ADMINS_FILE="${TMP_DIR}/env/admins.txt" \
WHITELIST_FILE="${TMP_DIR}/env/whitelist.txt" \
BLOCKLIST_FILE="${TMP_DIR}/env/blocklist.txt" \
CLUSTER_DATA_DIR="${TMP_DIR}/data/cluster" \
bash scripts/set_access_lists.sh > "${TMP_DIR}/out.log" 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -ne 0 ]]; then
  cat "${TMP_DIR}/out.log"
  echo "Expected set_access_lists.sh to succeed"
  exit 1
fi

grep -q '^KU_J9MSQD54$' "${TMP_DIR}/data/cluster/adminlist.txt"
grep -q '^KU_0PX1vpn8$' "${TMP_DIR}/data/cluster/whitelist.txt"
grep -q '^KU_BLOCK12345$' "${TMP_DIR}/data/cluster/blocklist.txt"
echo "PASS: set_access_lists.sh writes all list files"
