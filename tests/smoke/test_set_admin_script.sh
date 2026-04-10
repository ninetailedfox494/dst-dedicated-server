#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/env" "${TMP_DIR}/data/cluster"
cat > "${TMP_DIR}/env/admins.txt" <<'EOF'
# admins
KU_J9MSQD54
KU_0PX1vpn8
EOF

set +e
ADMINS_FILE="${TMP_DIR}/env/admins.txt" \
CLUSTER_DATA_DIR="${TMP_DIR}/data/cluster" \
bash scripts/set_admin.sh > "${TMP_DIR}/out.log" 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -ne 0 ]]; then
  cat "${TMP_DIR}/out.log"
  echo "Expected set_admin.sh to succeed"
  exit 1
fi

grep -q '^KU_J9MSQD54$' "${TMP_DIR}/data/cluster/adminlist.txt"
grep -q '^KU_0PX1vpn8$' "${TMP_DIR}/data/cluster/adminlist.txt"
echo "PASS: set_admin.sh writes adminlist.txt"
