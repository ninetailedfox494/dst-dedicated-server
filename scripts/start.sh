#!/bin/bash
# scripts/start.sh — Start DST Master and Caves servers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

log "Starting DST Dedicated Server..."

# Check binary exists
if ! dst_binary_exists; then
    err "DST binary not found. Run setup_dst_server.sh first."
fi

# Check config exists
if ! config_exists; then
    err "Config files not found. Run setup_dst_server.sh first."
fi

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
    bash -c "cd '${DST_SERVER%/*}' && '${DST_SERVER}' -console -cluster '${DST_CLUSTER_NAME}' -shard Master"

log "Waiting for Master to initialize (10s)..."
sleep 10

# Start Caves shard
log "Starting Caves shard on port 10998..."
screen -dmS dst_caves \
    bash -c "cd '${DST_SERVER%/*}' && '${DST_SERVER}' -console -cluster '${DST_CLUSTER_NAME}' -shard Caves"

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
