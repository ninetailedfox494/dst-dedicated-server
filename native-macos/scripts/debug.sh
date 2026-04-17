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
mod_count=$(ls -1 "${MODS_DIR}" 2>/dev/null | wc -l)
log "Total: $mod_count mod files"
ls -1 "${MODS_DIR}" 2>/dev/null | head -10 || warn "No mods found"
log ""

log "WORLD SIZES:"
if [[ -d "${MASTER_DIR}/DoNotStarveTogether" ]]; then
    master_size=$(du -sh "${MASTER_DIR}/DoNotStarveTogether" 2>/dev/null | cut -f1)
    log "Master: $master_size"
fi
if [[ -d "${CAVES_DIR}/DoNotStarveTogether" ]]; then
    caves_size=$(du -sh "${CAVES_DIR}/DoNotStarveTogether" 2>/dev/null | cut -f1)
    log "Caves: $caves_size"
fi
log ""

log "RECENT LOG ERRORS:"
cluster_log_root="${HOME}/Documents/Klei/DoNotStarveTogether/${DST_CLUSTER_NAME}"
for shard in master caves; do
    shard_name="$(tr '[:lower:]' '[:upper:]' <<< "${shard:0:1}")${shard:1}"
    if [[ -f "${cluster_log_root}/${shard_name}/server_log.txt" ]]; then
        log "--- $shard ---"
        strings "${cluster_log_root}/${shard_name}/server_log.txt" 2>/dev/null | grep -i error | tail -3 || log "(no errors)"
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
