#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

export DST_CLUSTER_NAME="MyDediServer"
export DST_CLUSTER_TOKEN="pds-example-token"
export DST_CLUSTER_DISPLAY_NAME="NineTailedFox"
export DST_CLUSTER_DESCRIPTION="Docker DST server"
export DST_CLUSTER_PASSWORD="8"
export DST_GAME_MODE="endless"
export DST_MAX_PLAYERS="6"
export DST_WORLD_SIZE="small"
export DST_SHARD_NAME="Master"
export DST_INSTALL_DIR="${TMP_DIR}/dst_server"
export DST_CLUSTER_ROOT="${TMP_DIR}/.klei/DoNotStarveTogether"
export DST_CLUSTER_DIR="${DST_CLUSTER_ROOT}/${DST_CLUSTER_NAME}"
export DST_TEST_MODE="1"

mkdir -p "${DST_INSTALL_DIR}/bin64"
touch "${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64"
chmod +x "${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64"

bash docker/entrypoint.sh >/dev/null 2>&1

grep -q "cluster_name = NineTailedFox" "${DST_CLUSTER_DIR}/cluster.ini"
grep -q "world_size = \"small\"" "${DST_CLUSTER_DIR}/Master/worldgenoverride.lua"
grep -q "is_master = true" "${DST_CLUSTER_DIR}/Master/server.ini"
echo "PASS: templates rendered"
