#!/bin/bash
# scripts/update_server.sh — Update DST server binary

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

log "Stopping servers..."
bash "${SCRIPT_DIR}/scripts/stop.sh" >/dev/null 2>&1 || true
sleep 3

log "Updating DST server..."

"${PROJECT_ROOT}/steamcmd/steamcmd.sh" \
    +force_install_dir "${PROJECT_ROOT}/dst_server" \
    +login anonymous \
    +app_update 343050 validate \
    +quit

success "DST server updated"
log ""
log "Restarting servers..."
bash "${SCRIPT_DIR}/scripts/start.sh"
