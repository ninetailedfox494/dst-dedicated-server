#!/bin/bash
# scripts/update_mods.sh — Update mods from env/mods.txt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

log "Stopping servers..."
bash "${SCRIPT_DIR}/scripts/stop.sh" >/dev/null 2>&1 || true
sleep 3

log "Reading mods from env/mods.txt..."

# Clear old mods
log "Removing old mod files..."
rm -rf "${MODS_DIR}"/*

# Download new mods
mod_count=0
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    mod_id=$(echo "$line" | awk '{print $1}')
    
    if [[ -n "$mod_id" ]]; then
        log "Downloading mod: $mod_id"
        "${PROJECT_ROOT}/steamcmd/steamcmd.sh" \
            +force_install_dir "${MODS_DIR}" \
            +login anonymous \
            +workshop_download_item 322330 "$mod_id" validate \
            +quit
        ((mod_count++))
    fi
done < "${PROJECT_ROOT}/env/mods.txt"

success "Downloaded $mod_count mod(s)"
sync_mod_configs

log "Restarting servers..."
bash "${SCRIPT_DIR}/scripts/start.sh"
