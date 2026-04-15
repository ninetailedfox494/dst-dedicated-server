#!/bin/bash
# scripts/backup.sh — Create world backup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

local label="${1:-manual}"
local backup_file="${BACKUPS_DIR}/${label}-$(timestamp).tar.gz"

log "Creating backup: $label"

# Stop servers before backup
if session_exists "dst_master" || session_exists "dst_caves"; then
    log "Stopping servers for backup..."
    bash "${SCRIPT_DIR}/scripts/stop.sh" >/dev/null 2>&1 || true
    sleep 3
fi

log "Archiving world data to:"
log "  $backup_file"

mkdir -p "${BACKUPS_DIR}"

# Create backup (exclude mods, steamcmd, binaries)
tar -czf "$backup_file" \
    -C "${DATA_DIR}" \
    cluster master caves \
    2>/dev/null || {
    err "Backup creation failed"
}

local size=$(stat -f%z "$backup_file" 2>/dev/null || echo 0)
success "Backup created: $(human_size $size)"
log "Location: $backup_file"

# Restart servers
log ""
log "Restarting servers..."
bash "${SCRIPT_DIR}/scripts/start.sh"
