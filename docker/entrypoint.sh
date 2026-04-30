#!/usr/bin/env bash
set -euo pipefail

required_vars=(DST_CLUSTER_NAME DST_CLUSTER_TOKEN)
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: ${var} is required" >&2
    exit 1
  fi
done

DST_INSTALL_DIR="${DST_INSTALL_DIR:-/home/dst/dst_server}"
DST_KLEI_ROOT="/home/dst/.klei"
DST_CLUSTER_ROOT="${DST_KLEI_ROOT}/DoNotStarveTogether"
DST_CLUSTER_DIR="${DST_CLUSTER_ROOT}/${DST_CLUSTER_NAME}"

MASTER_DIR="${DST_CLUSTER_DIR}/Master"
CAVES_DIR="${DST_CLUSTER_DIR}/Caves"
MODS_DIR="${DST_INSTALL_DIR}/mods"

STEAMCMD_PATH="/home/dst/steamcmd/steamcmd.sh"

export HOME=/home/dst

# ---------------- PERMISSION ----------------
mkdir -p "${DST_INSTALL_DIR}" "${DST_CLUSTER_ROOT}"
chown -R dst:dst /home/dst

# =========================================================
# 🔥 FIX STEAM WORKSHOP (REAL FIX)
# =========================================================

STEAM_ROOT="/home/dst/.steam/steam"
STEAM_APPS="${STEAM_ROOT}/steamapps"

mkdir -p "${STEAM_APPS}/workshop/content"
mkdir -p "${STEAM_APPS}/downloading"
mkdir -p "${STEAM_APPS}/temp"
mkdir -p "${STEAM_APPS}/common"

# 🔥 FIX 1: link DST install với steamapps
ln -sfn "${STEAM_APPS}" "${DST_INSTALL_DIR}/steamapps"

# 🔥 FIX 2: libraryfolders.vdf chuẩn
cat > "${STEAM_APPS}/libraryfolders.vdf" <<EOF
"libraryfolders"
{
    "0"
    {
        "path" "${STEAM_ROOT}"
        "label" ""
        "contentid" "0"
        "totalsize" "0"
    }
}
EOF

chown -R dst:dst /home/dst/.steam

# =========================================================

# ---------------- INSTALL DST ----------------
if [[ ! -f "${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64" ]]; then
  echo "Installing DST..."

  gosu dst "${STEAMCMD_PATH}" \
    +force_install_dir "${DST_INSTALL_DIR}" \
    +login anonymous \
    +app_update 343050 validate \
    +quit || {

    echo "Retrying SteamCMD..."
    gosu dst "${STEAMCMD_PATH}" \
      +force_install_dir "${DST_INSTALL_DIR}" \
      +login anonymous \
      +app_update 343050 \
      +quit
  }
fi

# ---------------- CLUSTER ----------------
mkdir -p "${MASTER_DIR}" "${CAVES_DIR}" "${MODS_DIR}"

echo "${DST_CLUSTER_TOKEN}" > "${DST_CLUSTER_DIR}/cluster_token.txt"

cat > "${DST_CLUSTER_DIR}/cluster.ini" <<EOF
[GAMEPLAY]
game_mode = endless
max_players = 6

[NETWORK]
cluster_name = ${DST_CLUSTER_NAME}
cluster_intention = cooperative

[SHARD]
shard_enabled = true
bind_ip = 0.0.0.0
master_ip = 127.0.0.1
master_port = 10888
cluster_key = defaultPass
EOF

# Master
cat > "${MASTER_DIR}/server.ini" <<EOF
[NETWORK]
server_port = 10999
[SHARD]
is_master = true
[STEAM]
master_server_port = 27016
authentication_port = 8766
EOF

# Caves
cat > "${CAVES_DIR}/server.ini" <<EOF
[NETWORK]
server_port = 10998
[SHARD]
is_master = false
name = Caves
[STEAM]
master_server_port = 27017
authentication_port = 8767
EOF

# ---------------- MOD ----------------
MODS_FILE="/home/dst/docker/env/mods.txt"
TMP_MOD_SETUP="$(mktemp)"
TMP_MODOVERRIDES="$(mktemp)"

if [[ -f "${MODS_FILE}" ]]; then
  awk -v setup_file="${TMP_MOD_SETUP}" -v overrides_file="${TMP_MODOVERRIDES}" '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }

    function brace_delta(line,   tmp, opens, closes) {
      tmp = line
      opens = gsub(/\{/, "{", tmp)
      tmp = line
      closes = gsub(/\}/, "}", tmp)
      return opens - closes
    }

    function add_id(id) {
      if (id == "") {
        return
      }
      if (!(id in seen_ids)) {
        seen_ids[id] = 1
        ordered_ids[++ordered_len] = id
      }
    }

    function start_override(id, first_line) {
      in_override = 1
      current_id = id
      current_block = first_line ORS
      current_depth = brace_delta(first_line)
      if (current_depth <= 0) {
        finish_override()
      }
    }

    function finish_override(   block) {
      block = current_block
      if (block !~ /},[[:space:]]*$/) {
        sub(/[[:space:]]*$/, "", block)
        block = block ",\n"
      }
      override_blocks[current_id] = block
      add_id(current_id)

      in_override = 0
      current_id = ""
      current_block = ""
      current_depth = 0
    }

    BEGIN {
      print "-- auto generated" > setup_file
      print "return {" > overrides_file
    }

    {
      raw = $0

      if (in_override) {
        current_block = current_block raw ORS
        current_depth += brace_delta(raw)
        if (current_depth <= 0) {
          finish_override()
        }
        next
      }

      if (raw ~ /^[[:space:]]*Mods[[:space:]]*=[[:space:]]*\{[[:space:]]*$/) {
        in_mods_table = 1
        next
      }

      # Parse explicit overwrite blocks anywhere outside Mods table.
      if (!in_mods_table && match(raw, /\["workshop-[0-9]+"\][[:space:]]*=[[:space:]]*\{/)) {
        id = substr(raw, RSTART, RLENGTH)
        sub(/^\["workshop-/, "", id)
        sub(/"\][[:space:]]*=[[:space:]]*\{$/, "", id)
        start_override(id, raw)
        next
      }

      if (in_mods_table) {
        if (raw ~ /^[[:space:]]*}[[:space:]]*,?[[:space:]]*$/) {
          in_mods_table = 0
          next
        }

        line = raw
        sub(/#.*/, "", line)
        sub(/--.*/, "", line)
        line = trim(line)
        sub(/,[[:space:]]*$/, "", line)
        if (line ~ /^[0-9]+$/) {
          add_id(line)
        }
        next
      }

      # Backward compatibility for legacy plain ID format.
      line = raw
      sub(/#.*/, "", line)
      line = trim(line)
      if (line ~ /^[0-9]+$/) {
        add_id(line)
      }
    }

    END {
      if (in_override) {
        finish_override()
      }

      for (i = 1; i <= ordered_len; i++) {
        id = ordered_ids[i]
        print "ServerModSetup(\"" id "\")" >> setup_file
      }

      for (i = 1; i <= ordered_len; i++) {
        id = ordered_ids[i]
        if (id in override_blocks) {
          printf "%s", override_blocks[id] >> overrides_file
        } else {
          print "  [\"workshop-" id "\"] = { enabled = true }," >> overrides_file
        }
      }

      print "}" >> overrides_file
    }
  ' "${MODS_FILE}"

  mv "${TMP_MOD_SETUP}" "${MODS_DIR}/dedicated_server_mods_setup.lua"
  mv "${TMP_MODOVERRIDES}" "${MASTER_DIR}/modoverrides.lua"
  cp "${MASTER_DIR}/modoverrides.lua" "${CAVES_DIR}/modoverrides.lua"
else
  echo "WARNING: ${MODS_FILE} not found, no mods will be installed" >&2
  echo "-- auto generated" > "${MODS_DIR}/dedicated_server_mods_setup.lua"
  echo "return {}" > "${MASTER_DIR}/modoverrides.lua"
  echo "return {}" > "${CAVES_DIR}/modoverrides.lua"
fi

rm -f "${TMP_MOD_SETUP}" "${TMP_MODOVERRIDES}"

chown -R dst:dst "${DST_CLUSTER_ROOT}" "${DST_INSTALL_DIR}"

# ---------------- RUN ----------------
BIN="${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64"

echo "Starting Master + Caves..."

cd "${DST_INSTALL_DIR}/bin64"

gosu dst ./dontstarve_dedicated_server_nullrenderer_x64 \
  -cluster "${DST_CLUSTER_NAME}" \
  -shard Master \
  -persistent_storage_root "${DST_KLEI_ROOT}" &

PID_MASTER=$!

gosu dst ./dontstarve_dedicated_server_nullrenderer_x64 \
  -cluster "${DST_CLUSTER_NAME}" \
  -shard Caves \
  -persistent_storage_root "${DST_KLEI_ROOT}" &

PID_CAVES=$!

trap "kill $PID_MASTER $PID_CAVES" SIGINT SIGTERM

wait -n

echo "One shard exited, stopping others..."
kill $PID_MASTER $PID_CAVES 2>/dev/null || true

wait
