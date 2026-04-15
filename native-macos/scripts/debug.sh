#!/bin/bash
# scripts/debug.sh — Advanced debugging info

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

log "═══════════════════════════════════════════════════════"
log "  DST Server Debug Info"
log "═══════════════════════════════════════════════════════"
log ""

log "CLUSTER CONFIG:"
cat "${CLUSTER_DIR}/cluster.ini" 2>/dev/null | grep -E "^\[|=" || warn "cluster.ini not found"
log ""

log "INSTALLED MODS:"
local mod_count=$(ls -1 "${MODS_DIR}" 2>/dev/null | wc -l)
log "Total: $mod_count mod files"
ls -1 "${MODS_DIR}" 2>/dev/null | head -10 || warn "No mods found"
log ""

log "WORLD SIZES:"
if [[ -d "${MASTER_DIR}/DoNotStarveTogether" ]]; then
    local master_size=$(du -sh "${MASTER_DIR}/DoNotStarveTogether" 2>/dev/null | cut -f1)
    log "Master: $master_size"
fi
if [[ -d "${CAVES_DIR}/DoNotStarveTogether" ]]; then
    local caves_size=$(du -sh "${CAVES_DIR}/DoNotStarveTogether" 2>/dev/null | cut -f1)
    log "Caves: $caves_size"
fi
log ""

log "RECENT LOG ERRORS:"
for shard in master caves; do
    if [[ -f "${DATA_DIR}/${shard}/dontstarve.log" ]]; then
        log "--- $shard ---"
        grep -i error "${DATA_DIR}/${shard}/dontstarve.log" 2>/dev/null | tail -3 || log "(no errors)"
    fi
done
log ""

log "NETWORK DIAGNOSTICS:"
if command -v lsof &>/dev/null; then
    lsof -i -P -n 2>/dev/null | grep -E "10999|10998|27016" || log "(ports not listening)"
else
    netstat -an | grep -E "10999|10998|27016" || log "(ports not listening)"
fi
log ""

log "FIREWALL STATUS (if UFW enabled):"
if command -v ufw &>/dev/null && sudo ufw status >/dev/null 2>&1; then
    sudo ufw status | grep -E "10999|10998" || warn "Ports may not be open in firewall"
else
    log "(UFW not available or not enabled)"
fi
log ""

log "═══════════════════════════════════════════════════════"
