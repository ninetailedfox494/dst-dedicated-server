#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

export DST_CLUSTER_NAME="MyDediServer"
unset DST_CLUSTER_TOKEN || true
export DST_SHARD_NAME="Master"
export DST_INSTALL_DIR="${TMP_DIR}/dst_server"
export DST_CLUSTER_ROOT="${TMP_DIR}/.klei/DoNotStarveTogether"
export DST_CLUSTER_DIR="${DST_CLUSTER_ROOT}/${DST_CLUSTER_NAME}"
export DST_TEST_MODE="1"

mkdir -p "${DST_INSTALL_DIR}/bin64"
touch "${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64"
chmod +x "${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64"

set +e
bash docker/entrypoint.sh >"${TMP_DIR}/out.log" 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -eq 0 ]]; then
  echo "Expected failure when DST_CLUSTER_TOKEN missing"
  exit 1
fi

grep -q "DST_CLUSTER_TOKEN is required" "${TMP_DIR}/out.log"
echo "PASS: missing token fails fast"
