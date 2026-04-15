#!/bin/bash
# scripts/logs.sh — View DST server logs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

local log_dir="${PROJECT_ROOT}/data"
local follow=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --follow|-f)
            follow="--follow"
            shift
            ;;
        master)
            local shard="master"
            shift
            ;;
        caves)
            local shard="caves"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# If no shard specified, show menu
if [[ -z "${shard:-}" ]]; then
    log "Which shard's logs?"
    log "  1) Master"
    log "  2) Caves"
    read -p "Choose (1-2): " choice
    
    case "$choice" in
        1) shard="master" ;;
        2) shard="caves" ;;
        *) err "Invalid choice" ;;
    esac
fi

local log_file="${log_dir}/${shard}/dontstarve.log"

if [[ ! -f "$log_file" ]]; then
    warn "Log file not found: $log_file"
    warn "Server may not have run yet. Try: bash scripts/start.sh"
    exit 1
fi

log "Showing $shard logs (last 100 lines):"
log "Press Ctrl+C to exit"
log ""

tail -n 100 ${follow} "$log_file"
