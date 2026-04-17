#!/bin/bash
# scripts/start.sh — Start DST Master and Caves servers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

log "Starting DST Dedicated Server..."

# Steam listing relies on Steam API env and steamclient runtime loading.
steam_launch_env="SteamAppId=322330 SteamGameId=322330"
if steamclient_dylib="$(resolve_steamclient_dylib)"; then
    steamclient_dir="$(dirname "$steamclient_dylib")"
    steam_launch_env="${steam_launch_env} DYLD_LIBRARY_PATH='${steamclient_dir}'"
    log "Using steamclient from: $steamclient_dylib"
else
    warn "steamclient.dylib not found; server may run but not appear in Browse Games"
fi

# Check binary exists
if ! dst_binary_exists; then
    err "DST binary not found. Run setup_dst_server.sh first."
fi

# Check config exists
if ! config_exists; then
    err "Config files not found. Run setup_dst_server.sh first."
fi

sync_mod_configs

if [[ ! -x "${DST_SERVER_STEAM_BIN64}" && -x "${DST_SERVER_APP}" ]]; then
    cp "${DST_SERVER_APP}" "${DST_SERVER_STEAM_BIN64}"
    chmod +x "${DST_SERVER_STEAM_BIN64}"
    log "Created Steam-capable runtime at: ${DST_SERVER_STEAM_BIN64}"
fi

runtime_binary="$(dst_runtime_binary)"
log "Runtime binary: $runtime_binary"

# Kill old sessions if they exist
for session in dst_master dst_caves; do
    if session_exists "$session"; then
        log "Stopping existing $session session..."
        screen -S "$session" -X quit 2>/dev/null || true
    fi
done
sleep 2

# Start Master shard
log "Starting Master shard on port 10999..."
screen -dmS dst_master \
    bash -lc "cd '${runtime_binary%/*}' && ${steam_launch_env} '${runtime_binary}' -console -cluster '${DST_CLUSTER_NAME}' -shard Master"

log "Waiting for Master to initialize (10s)..."
sleep 10

# Start Caves shard
log "Starting Caves shard on port 10998..."
screen -dmS dst_caves \
    bash -lc "cd '${runtime_binary%/*}' && ${steam_launch_env} '${runtime_binary}' -console -cluster '${DST_CLUSTER_NAME}' -shard Caves"

sleep 2

log ""
success "Servers started!"
log ""
log "📺 View logs:"
log "   Master: screen -r dst_master"
log "   Caves:  screen -r dst_caves"
log "   Exit screen: Ctrl+A then D (detach)"
log ""
log "Check status:"
log "   bash scripts/status.sh"
log ""
