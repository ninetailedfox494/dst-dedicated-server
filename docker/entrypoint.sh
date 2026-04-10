#!/usr/bin/env bash
set -euo pipefail

required_vars=(DST_CLUSTER_NAME DST_CLUSTER_TOKEN DST_SHARD_NAME)
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: ${var} is required" >&2
    exit 1
  fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DST_INSTALL_DIR="${DST_INSTALL_DIR:-/home/dst/dst_server}"
DST_CLUSTER_ROOT="${DST_CLUSTER_ROOT:-/home/dst/.klei/DoNotStarveTogether}"
DST_CLUSTER_DIR="${DST_CLUSTER_DIR:-${DST_CLUSTER_ROOT}/${DST_CLUSTER_NAME}}"

DST_CLUSTER_DISPLAY_NAME="${DST_CLUSTER_DISPLAY_NAME:-${DST_CLUSTER_NAME}}"
DST_CLUSTER_DESCRIPTION="${DST_CLUSTER_DESCRIPTION:-DST Dedicated Server via Docker}"
DST_CLUSTER_PASSWORD="${DST_CLUSTER_PASSWORD:-}"
DST_GAME_MODE="${DST_GAME_MODE:-endless}"
DST_MAX_PLAYERS="${DST_MAX_PLAYERS:-6}"
DST_WORLD_SIZE="${DST_WORLD_SIZE:-small}"

MASTER_DIR="${DST_CLUSTER_DIR}/Master"
CAVES_DIR="${DST_CLUSTER_DIR}/Caves"
MODS_DIR="${DST_INSTALL_DIR}/mods"

mkdir -p "${MASTER_DIR}" "${CAVES_DIR}" "${MODS_DIR}"

cat > "${DST_CLUSTER_DIR}/cluster_token.txt" <<EOF
${DST_CLUSTER_TOKEN}
EOF

cat > "${DST_CLUSTER_DIR}/cluster.ini" <<EOF
[GAMEPLAY]
game_mode = ${DST_GAME_MODE}
max_players = ${DST_MAX_PLAYERS}
pvp = false
pause_when_empty = true
vote_enabled = true

[NETWORK]
cluster_name = ${DST_CLUSTER_DISPLAY_NAME}
cluster_description = ${DST_CLUSTER_DESCRIPTION}
cluster_password = ${DST_CLUSTER_PASSWORD}
cluster_intention = cooperative
lan_only_cluster = false
offline_cluster = false
tick_rate = 15
whitelist_slots = 0

[MISC]
console_enabled = true
max_snapshots = 6

[SHARD]
shard_enabled = true
bind_ip = 127.0.0.1
master_ip = 127.0.0.1
master_port = 10888
cluster_key = defaultPass
EOF

cat > "${MASTER_DIR}/server.ini" <<'EOF'
[NETWORK]
server_port = 10999

[SHARD]
is_master = true

[STEAM]
master_server_port = 27016
authentication_port = 8766
EOF

cat > "${CAVES_DIR}/server.ini" <<'EOF'
[NETWORK]
server_port = 10998

[SHARD]
is_master = false
name = Caves

[STEAM]
master_server_port = 27017
authentication_port = 8767
EOF

cat > "${MASTER_DIR}/worldgenoverride.lua" <<EOF
return {
    override_enabled = true,
    overrides = {
        world_size = "${DST_WORLD_SIZE}",
    },
}
EOF

cat > "${CAVES_DIR}/worldgenoverride.lua" <<EOF
return {
    override_enabled = true,
    preset = "DST_CAVE",
    overrides = {
        world_size = "${DST_WORLD_SIZE}",
    },
}
EOF

if [[ ! -f "${MASTER_DIR}/modoverrides.lua" ]]; then
  cat "${SCRIPT_DIR}/templates/modoverrides.lua.tmpl" > "${MASTER_DIR}/modoverrides.lua"
fi
if [[ ! -f "${CAVES_DIR}/modoverrides.lua" ]]; then
  cat "${SCRIPT_DIR}/templates/modoverrides.lua.tmpl" > "${CAVES_DIR}/modoverrides.lua"
fi

if [[ ! -f "${MODS_DIR}/dedicated_server_mods_setup.lua" ]]; then
  cat > "${MODS_DIR}/dedicated_server_mods_setup.lua" <<'EOF'
ServerModSetup("2798599672")
ServerModSetup("374550642")
ServerModSetup("1207269058")
ServerModSetup("2477889104")
ServerModSetup("378160973")
ServerModSetup("351325790")
ServerModSetup("362175979")
ServerModSetup("597417408")
ServerModSetup("569043634")
ServerModSetup("2189004162")
ServerModSetup("1852257480")
EOF
fi

if [[ "${DST_TEST_MODE:-0}" == "1" ]]; then
  echo "Test mode enabled. Config generation complete."
  exit 0
fi

BIN="${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64"
if [[ ! -x "${BIN}" ]]; then
  echo "ERROR: DST binary not found at ${BIN}" >&2
  exit 1
fi

exec "${BIN}" \
  -console \
  -cluster "${DST_CLUSTER_NAME}" \
  -shard "${DST_SHARD_NAME}"
