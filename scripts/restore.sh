#!/bin/bash
# scripts/restore.sh — Restore world from backup

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

log "Available backups:"
log ""

local backups=($(ls -t "${BACKUPS_DIR}"/*.tar.gz 2>/dev/null || echo ""))

if [[ ${#backups[@]} -eq 0 ]]; then
    err "No backups found in ${BACKUPS_DIR}/"
fi

local i=1
for backup in "${backups[@]}"; do
    local size=$(stat -f%z "$backup" 2>/dev/null || echo 0)
    local name=$(basename "$backup")
    log "  $i) $name ($(human_size $size))"
    ((i++))
done

read -p "Choose backup to restore (number): " choice

local backup="${backups[$((choice-1))]}"

if [[ ! -f "$backup" ]]; then
    err "Invalid backup selection"
fi

log ""
warn "⚠️  RESTORING WILL OVERWRITE CURRENT WORLDS"
read -p "Are you sure? Type 'yes' to confirm: " confirm

if [[ "$confirm" != "yes" ]]; then
    log "Cancelled."
    exit 0
fi

log "Stopping servers..."
bash "${SCRIPT_DIR}/scripts/stop.sh" >/dev/null 2>&1 || true
sleep 3

log "Restoring from: $(basename "$backup")"
tar -xzf "$backup" -C "${DATA_DIR}" 2>/dev/null || {
    err "Restore failed"
}

success "Restore complete"
log ""
log "Restarting servers..."
bash "${SCRIPT_DIR}/scripts/start.sh"
