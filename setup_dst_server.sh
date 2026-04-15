#!/bin/bash
# setup_dst_server.sh — Don't Starve Together Dedicated Server Setup (macOS)
# Usage: bash setup_dst_server.sh

set -euo pipefail

# Source shared library first
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

# ═══════════════════════════════════════════════════════════
#  PHASE 1: PREREQUISITES CHECK
# ═══════════════════════════════════════════════════════════

phase_1_prerequisites() {
    log "PHASE 1/10: Checking prerequisites..."
    
    # Check OS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        err "This script is designed for macOS only. Detected OS: $OSTYPE"
    fi
    log "✅ Running on macOS"
    
    # Check Bash version
    BASH_VERSION_MAJOR="${BASH_VERSION%%.*}"
    if [[ $BASH_VERSION_MAJOR -lt 4 ]]; then
        warn "Bash version is $BASH_VERSION (require 4+)"
        warn "Consider: brew install bash && chsh -s /usr/local/bin/bash"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] || exit 1
    fi
    log "✅ Bash version: $BASH_VERSION"
    
    # Check env/.env exists
    if [[ ! -f "${PROJECT_ROOT}/env/.env" ]]; then
        warn "env/.env not found"
        if [[ -f "${PROJECT_ROOT}/env/.env.template" ]]; then
            log "Copying env/.env.template → env/.env"
            cp "${PROJECT_ROOT}/env/.env.template" "${PROJECT_ROOT}/env/.env"
            log "⚠️  Please edit env/.env with your Klei token and settings"
            log "    vi env/.env"
        else
            err "Neither env/.env nor env/.env.template found"
        fi
    fi
    log "✅ env/.env exists"
    
    # Check mods.txt
    if [[ ! -f "${PROJECT_ROOT}/env/mods.txt" ]]; then
        warn "env/mods.txt not found"
        if [[ -f "${PROJECT_ROOT}/env/mods.txt.template" ]]; then
            cp "${PROJECT_ROOT}/env/mods.txt.template" "${PROJECT_ROOT}/env/mods.txt"
            log "Created env/mods.txt from template"
        fi
    fi
    
    log "✅ PHASE 1 complete: Prerequisites OK"
}

# ═══════════════════════════════════════════════════════════
#  PHASE 2: CREATE DIRECTORY STRUCTURE
# ═══════════════════════════════════════════════════════════

phase_2_directories() {
    log "PHASE 2/10: Creating directory structure..."
    
    mkdir -p "${DATA_DIR}/cluster"
    mkdir -p "${DATA_DIR}/master"
    mkdir -p "${DATA_DIR}/caves"
    mkdir -p "${DATA_DIR}/mods"
    mkdir -p "${DATA_DIR}/backups"
    mkdir -p "${PROJECT_ROOT}/steamcmd"
    mkdir -p "${PROJECT_ROOT}/env"
    mkdir -p "${PROJECT_ROOT}/scripts"
    
    log "✅ Directories created:"
    log "   data/cluster/, data/master/, data/caves/"
    log "   data/mods/, data/backups/"
    log "   steamcmd/, env/, scripts/"
}

# ═══════════════════════════════════════════════════════════
#  PHASE 3: HOMEBREW DEPENDENCIES
# ═══════════════════════════════════════════════════════════

phase_3_homebrew() {
    log "PHASE 3/10: Installing Homebrew dependencies..."
    
    # Check if Homebrew installed
    if ! command -v brew &>/dev/null; then
        err "Homebrew not found. Install from: https://brew.sh"
    fi
    log "✅ Homebrew found"
    
    # Install dependencies
    local packages=("screen" "wget" "curl")
    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            log "✅ $pkg already installed"
        else
            log "📦 Installing $pkg..."
            brew install "$pkg"
            log "✅ $pkg installed"
        fi
    done
    
    log "✅ PHASE 3 complete: Dependencies installed"
}

# ═══════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════

main() {
    log "╔════════════════════════════════════════════════════╗"
    log "║  DST Dedicated Server Setup — macOS Native         ║"
    log "║  Project Root: ${PROJECT_ROOT}"
    log "╚════════════════════════════════════════════════════╝"
    log ""
    
    phase_1_prerequisites
    log ""
    phase_2_directories
    log ""
    phase_3_homebrew
    log ""
    
    log "✅ Setup phases 1-3 complete!"
    log "Continue with: bash setup_dst_server.sh --continue-phase-5"
}

main "$@"
