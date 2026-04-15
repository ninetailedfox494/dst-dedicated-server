#!/bin/bash
# scripts/_lib.sh — Shared functions for DST server management

set -euo pipefail

# ═══════════════════════════════════════════════════════════
#  COLOR DEFINITIONS
# ═══════════════════════════════════════════════════════════
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color

# ═══════════════════════════════════════════════════════════
#  LOGGING FUNCTIONS
# ═══════════════════════════════════════════════════════════

log() {
    echo -e "${GREEN}[DST-SERVER]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $*" >&2
}

err() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}✅ $*${NC}"
}

debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*" >&2
    fi
}

# ═══════════════════════════════════════════════════════════
#  ENVIRONMENT & PATHS
# ═══════════════════════════════════════════════════════════

# Get script directory (handles both direct execution and sourcing)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"
DATA_DIR="${PROJECT_ROOT}/data"
CLUSTER_DIR="${DATA_DIR}/cluster"
MASTER_DIR="${DATA_DIR}/master"
CAVES_DIR="${DATA_DIR}/caves"
MODS_DIR="${DATA_DIR}/mods"
BACKUPS_DIR="${DATA_DIR}/backups"
DST_SERVER="${PROJECT_ROOT}/dst_server/bin64/dontstarve_dedicated_server_nullrenderer_x64"

# ═══════════════════════════════════════════════════════════
#  ENV LOADING
# ═══════════════════════════════════════════════════════════

source_env() {
    local env_file="${PROJECT_ROOT}/env/.env"
    if [[ ! -f "$env_file" ]]; then
        err "env/.env not found. Copy env/.env.template to env/.env first."
    fi
    # Safely source env file
    set -a
    source "$env_file"
    set +a
}

# ═══════════════════════════════════════════════════════════
#  UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════

# Check if screen session exists
session_exists() {
    local session_name="$1"
    screen -list 2>/dev/null | grep -q "\.${session_name}\s" && return 0 || return 1
}

# Get PID of screen session
get_session_pid() {
    local session_name="$1"
    local pid=$(screen -list 2>/dev/null | grep "\.${session_name}\s" | grep -o '[0-9]\+' | head -1)
    [[ -n "$pid" ]] && echo "$pid" || echo ""
}

# Check if port is listening
port_listening() {
    local port="$1"
    local protocol="${2:-udp}"
    lsof -i "${protocol}:${port}" >/dev/null 2>&1 && return 0 || return 1
}

# Format timestamp for backups
timestamp() {
    date +%Y%m%d-%H%M%S
}

# Get human-readable file size
human_size() {
    local bytes="$1"
    if [[ $bytes -ge 1073741824 ]]; then
        echo "$((bytes / 1073741824))GB"
    elif [[ $bytes -ge 1048576 ]]; then
        echo "$((bytes / 1048576))MB"
    elif [[ $bytes -ge 1024 ]]; then
        echo "$((bytes / 1024))KB"
    else
        echo "${bytes}B"
    fi
}

# Check if DST binary exists
dst_binary_exists() {
    [[ -x "$DST_SERVER" ]]
}

# Check if config files exist
config_exists() {
    [[ -f "${CLUSTER_DIR}/cluster.ini" && -f "${CLUSTER_DIR}/cluster_token.txt" ]]
}

export -f log warn err info success debug
export -f session_exists get_session_pid port_listening timestamp human_size
export -f dst_binary_exists config_exists
export -f source_env
export PROJECT_ROOT DATA_DIR CLUSTER_DIR MASTER_DIR CAVES_DIR MODS_DIR BACKUPS_DIR DST_SERVER
export RED GREEN YELLOW BLUE CYAN NC
