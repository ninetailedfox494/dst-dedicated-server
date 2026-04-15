#!/bin/bash
# scripts/recovery.sh — Auto-restart crashed shards

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

# Daemon mode (continuous monitoring)
if [[ "${1:-}" == "--daemon" ]]; then
    log "Starting recovery daemon (Ctrl+C to stop)..."
    while true; do
        # Check Master
        if ! session_exists "dst_master"; then
            warn "Master shard crashed! Restarting..."
            log "[$(date '+%Y-%m-%d %H:%M:%S')] Master restart" >> "${BACKUPS_DIR}/recovery.log"
            bash "${SCRIPT_DIR}/scripts/start.sh" >/dev/null 2>&1 || true
        fi
        
        # Check Caves
        if ! session_exists "dst_caves"; then
            warn "Caves shard crashed! Restarting..."
            log "[$(date '+%Y-%m-%d %H:%M:%S')] Caves restart" >> "${BACKUPS_DIR}/recovery.log"
            sleep 15
            "${PROJECT_ROOT}/dst_server/bin64/dontstarve_dedicated_server_nullrenderer_x64" \
                -console -cluster "${DST_CLUSTER_NAME}" -shard Caves &
        fi
        
        sleep 30
    done
else
    # Single check mode
    log "Checking server health..."
    
    if session_exists "dst_master"; then
        success "Master shard running"
    else
        warn "Master shard not running"
    fi
    
    if session_exists "dst_caves"; then
        success "Caves shard running"
    else
        warn "Caves shard not running"
    fi
fi
