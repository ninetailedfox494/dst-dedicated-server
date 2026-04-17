#!/bin/bash
# scripts/stop.sh — Gracefully stop DST servers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

log "Stopping DST servers..."

# Send shutdown command to Caves first
if session_exists "dst_caves"; then
    log "Shutting down Caves shard..."
    screen -S dst_caves -X stuff "c_shutdown(true)$(printf '\r')" 2>/dev/null
    sleep 5
else
    log "Caves shard not running"
fi

# Send shutdown command to Master
if session_exists "dst_master"; then
    log "Shutting down Master shard..."
    screen -S dst_master -X stuff "c_shutdown(true)$(printf '\r')" 2>/dev/null
    sleep 5
else
    log "Master shard not running"
fi

# Force quit if still running
for session in dst_caves dst_master; do
    if session_exists "$session"; then
        log "Force-quitting $session..."
        screen -S "$session" -X quit 2>/dev/null || true
    fi
done

sleep 1
log ""
success "Servers stopped!"
log ""
