#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/env" "${TMP_DIR}/data/mods" "${TMP_DIR}/cluster/Master" "${TMP_DIR}/cluster/Caves"
cat > "${TMP_DIR}/env/mods.txt" <<'EOF'
Mods = {
  569043634
  2189004162
}

Overwrite_Mods = {
  ["workshop-375850593"] = {
    configuration_options = {},
    enabled = true
  }
}
EOF

set +e
DST_CLUSTER_NAME="MyDediServer" \
DST_CLUSTER_ROOT="${TMP_DIR}/cluster-root" \
DST_CLUSTER_DIR="${TMP_DIR}/cluster" \
DST_INSTALL_DIR="${TMP_DIR}/dst" \
MODS_FILE="${TMP_DIR}/env/mods.txt" \
DST_TEST_MODE="1" \
bash scripts/reset_and_install_mods_docker.sh >"${TMP_DIR}/out.log" 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -ne 0 ]]; then
  cat "${TMP_DIR}/out.log"
  echo "Expected structured mods.txt parsing to succeed"
  exit 1
fi

grep -q 'ServerModSetup("569043634")' "${TMP_DIR}/dst/mods/dedicated_server_mods_setup.lua"
grep -q 'ServerModSetup("2189004162")' "${TMP_DIR}/dst/mods/dedicated_server_mods_setup.lua"
grep -q 'ServerModSetup("375850593")' "${TMP_DIR}/dst/mods/dedicated_server_mods_setup.lua"
if grep -q 'ServerModSetup("Mods={' "${TMP_DIR}/dst/mods/dedicated_server_mods_setup.lua"; then
  echo "Structured markers leaked into mod IDs"
  exit 1
fi
echo "PASS: mod updater parses structured mods.txt correctly"
