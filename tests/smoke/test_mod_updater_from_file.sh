#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

export DST_CLUSTER_NAME="MyDediServer"
export DST_CLUSTER_ROOT="${TMP_DIR}/.klei/DoNotStarveTogether"
export DST_CLUSTER_DIR="${DST_CLUSTER_ROOT}/${DST_CLUSTER_NAME}"
export DST_INSTALL_DIR="${TMP_DIR}/dst_server"
export DST_APP_ID="322330"
export MODS_FILE="${TMP_DIR}/mods.txt"
export DST_TEST_MODE="1"

mkdir -p "${DST_INSTALL_DIR}/mods"
mkdir -p "${DST_CLUSTER_DIR}/Master" "${DST_CLUSTER_DIR}/Caves"
cat > "${MODS_FILE}" <<'EOF'
# comment
2798599672
374550642
EOF

set +e
bash scripts/reset_and_install_mods_docker.sh >"${TMP_DIR}/out.log" 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -ne 0 ]]; then
  cat "${TMP_DIR}/out.log"
  echo "Expected test mode run to succeed"
  exit 1
fi

grep -q 'ServerModSetup("2798599672")' "${DST_INSTALL_DIR}/mods/dedicated_server_mods_setup.lua"
grep -q 'workshop-374550642' "${DST_CLUSTER_DIR}/Master/modoverrides.lua"
grep -q 'workshop-374550642' "${DST_CLUSTER_DIR}/Caves/modoverrides.lua"
echo "PASS: mod updater reads mods file and writes config"
