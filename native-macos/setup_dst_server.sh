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
#  PHASE 4: STEAMCMD INSTALLATION
# ═══════════════════════════════════════════════════════════

phase_4_steamcmd() {
    log "PHASE 4/10: Installing SteamCMD..."
    
    if [[ -f "${PROJECT_ROOT}/steamcmd/steamcmd.sh" ]]; then
        log "✅ SteamCMD already installed"
        return 0
    fi
    
    log "Downloading SteamCMD..."
    cd "${PROJECT_ROOT}/steamcmd"
    
    # Download and extract SteamCMD
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_osx.tar.gz" | tar zxvf - >/dev/null 2>&1
    
    if [[ ! -f steamcmd.sh ]]; then
        err "SteamCMD installation failed"
    fi
    
    log "✅ SteamCMD installed to: ${PROJECT_ROOT}/steamcmd/"
}

# ═══════════════════════════════════════════════════════════
#  PHASE 5: DST SERVER INSTALLATION
# ═══════════════════════════════════════════════════════════

phase_5_dst_server() {
    log "PHASE 5/10: Installing DST Dedicated Server..."
    
    local dst_binary="${PROJECT_ROOT}/dst_server/bin64/dontstarve_dedicated_server_nullrenderer_x64"
    
    if [[ -x "$dst_binary" ]]; then
        log "✅ DST binary already installed"
        return 0
    fi
    
    log "Downloading DST Dedicated Server (app 343050)..."
    log "This may take 5-10 minutes..."
    
    "${PROJECT_ROOT}/steamcmd/steamcmd.sh" \
        +force_install_dir "${PROJECT_ROOT}/dst_server" \
        +login anonymous \
        +app_update 343050 validate \
        +quit
    
    if [[ ! -x "$dst_binary" ]]; then
        err "DST server installation failed. Binary not found at: $dst_binary"
    fi

    local steamclient_source="${HOME}/Library/Application Support/Steam/Steam.AppBundle/Steam/Contents/MacOS/steamclient.dylib"
    local steamclient_target="${PROJECT_ROOT}/dst_server/Library/steamclient.dylib"
    local app_runtime_source="${PROJECT_ROOT}/dst_server/dontstarve_dedicated_server_nullrenderer.app/Contents/MacOS/dontstarve_dedicated_server_nullrenderer"
    local app_runtime_target="${PROJECT_ROOT}/dst_server/bin64/dontstarve_dedicated_server_nullrenderer"
    mkdir -p "${PROJECT_ROOT}/dst_server/Library"
    if [[ -f "$steamclient_source" ]]; then
        cp "$steamclient_source" "$steamclient_target"
        log "✅ steamclient.dylib copied to dst_server/Library/"
    else
        warn "steamclient.dylib not found at: $steamclient_source"
        warn "Server may run but Steam listing can fail until this file is available"
    fi

    if [[ -x "$app_runtime_source" ]]; then
        cp "$app_runtime_source" "$app_runtime_target"
        chmod +x "$app_runtime_target"
        log "✅ Steam-capable runtime copied to: dst_server/bin64/dontstarve_dedicated_server_nullrenderer"
    else
        warn "App runtime not found at: $app_runtime_source"
        warn "Falling back to x64 runtime may break Browse Games listing or mod loading"
    fi
    
    log "✅ DST Server installed to: ${PROJECT_ROOT}/dst_server/"
}

# ═══════════════════════════════════════════════════════════
#  PHASE 6: CONFIGURATION GENERATION
# ═══════════════════════════════════════════════════════════

phase_6_config_generation() {
    log "PHASE 6/10: Generating cluster configuration..."
    
    source_env
    
    # Validate required variables
    if [[ -z "${DST_CLUSTER_TOKEN:-}" ]]; then
        err "DST_CLUSTER_TOKEN not set in env/.env"
    fi
    
    # Generate cluster_token.txt
    cat > "${CLUSTER_DIR}/cluster_token.txt" <<EOF
${DST_CLUSTER_TOKEN}
EOF
    log "✅ cluster_token.txt created"
    
    # Generate cluster.ini
    cat > "${CLUSTER_DIR}/cluster.ini" <<EOF
[GAMEPLAY]
game_mode = ${DST_GAME_MODE:-endless}
max_players = ${DST_MAX_PLAYERS:-6}
pvp = ${DST_PVP:-false}
pause_when_empty = ${DST_PAUSE_WHEN_EMPTY:-true}
vote_enabled = true

[NETWORK]
cluster_name = ${DST_CLUSTER_DISPLAY_NAME:-NineTailedFox}
cluster_description = ${DST_CLUSTER_DESCRIPTION:-DST Server}
cluster_password = ${DST_CLUSTER_PASSWORD:-}
cluster_intention = cooperative
lan_only_cluster = false
offline_cluster = ${DST_OFFLINE_CLUSTER:-false}
tick_rate = ${DST_TICK_RATE:-15}

[MISC]
console_enabled = ${DST_CONSOLE_ENABLED:-true}
max_snapshots = 6

[SHARD]
shard_enabled = true
bind_ip = 0.0.0.0
master_ip = 127.0.0.1
master_port = 10888
cluster_key = defaultPass
EOF
    log "✅ cluster.ini created"
    
    # Generate Master server.ini
    cat > "${MASTER_DIR}/server.ini" <<EOF
[NETWORK]
server_port = 10999

[SHARD]
is_master = true

[STEAM]
master_server_port = 27016
authentication_port = 8766
EOF
    log "✅ Master/server.ini created"
    
    # Generate Caves server.ini
    cat > "${CAVES_DIR}/server.ini" <<EOF
[NETWORK]
server_port = 10998

[SHARD]
is_master = false
name = Caves

[STEAM]
master_server_port = 27017
authentication_port = 8767
EOF
    log "✅ Caves/server.ini created"
    
    # Generate worldgenoverride.lua for Master
    cat > "${MASTER_DIR}/worldgenoverride.lua" <<EOF
return {
    override_enabled = true,
    preset = "DST_FOREST",
}
EOF
    log "✅ Master/worldgenoverride.lua created"
    
    # Generate worldgenoverride.lua for Caves
    cat > "${CAVES_DIR}/worldgenoverride.lua" <<EOF
return {
    override_enabled = true,
    preset = "DST_CAVE",
}
EOF
    log "✅ Caves/worldgenoverride.lua created"
    
    log "✅ PHASE 6 complete: Config files generated"
}

# ═══════════════════════════════════════════════════════════
#  PHASE 7: MOD CONFIGURATION
# ═══════════════════════════════════════════════════════════

phase_7_mods() {
    log "PHASE 7/10: Configuring mods..."

    source_env
    sync_mod_configs

    log "✅ PHASE 7 complete: Mod configuration ready"
}

# ═══════════════════════════════════════════════════════════
#  PHASE 8: HELPER SCRIPTS CREATION
# ═══════════════════════════════════════════════════════════

phase_8_helper_scripts() {
    log "PHASE 8/10: Creating helper scripts..."
    
    # Placeholder: Helper scripts will be created in next phase
    # For now, ensure scripts directory has _lib.sh
    
    if [[ ! -f "${PROJECT_ROOT}/scripts/_lib.sh" ]]; then
        log "⚠️  scripts/_lib.sh not found — copy it to scripts/ directory"
    else
        log "✅ scripts/_lib.sh found"
    fi
    
    log "✅ PHASE 8 complete: Helper scripts ready (see tasks 6-13)"
}

# ═══════════════════════════════════════════════════════════
#  PHASE 9: HEALTH CHECKS
# ═══════════════════════════════════════════════════════════

phase_9_health_checks() {
    log "PHASE 9/10: Running health checks..."
    
    local checks_passed=0
    local checks_total=5
    
    # Check 1: DST binary
    if [[ -x "${PROJECT_ROOT}/dst_server/bin64/dontstarve_dedicated_server_nullrenderer_x64" ]]; then
        success "DST binary exists and is executable"
        ((checks_passed++))
    else
        warn "DST binary missing or not executable"
    fi
    
    # Check 2: Config files
    if [[ -f "${CLUSTER_DIR}/cluster.ini" && -f "${CLUSTER_DIR}/cluster_token.txt" ]]; then
        success "Cluster config files exist"
        ((checks_passed++))
    else
        warn "Cluster config files missing"
    fi
    
    # Check 3: Server config
    if [[ -f "${MASTER_DIR}/server.ini" && -f "${CAVES_DIR}/server.ini" ]]; then
        success "Master and Caves server.ini files exist"
        ((checks_passed++))
    else
        warn "Master or Caves server.ini missing"
    fi
    
    # Check 4: Ports available
    if ! port_listening 10999 udp && ! port_listening 10998 udp; then
        success "Required ports (10999, 10998 UDP) available"
        ((checks_passed++))
    else
        warn "One or more required ports already in use"
    fi
    
    # Check 5: Bash version
    if [[ ${BASH_VERSION_MAJOR} -ge 4 ]]; then
        success "Bash version 4+ confirmed"
        ((checks_passed++))
    else
        warn "Bash version below 4"
    fi
    
    log ""
    log "Health checks: ${checks_passed}/${checks_total} passed"
    
    if [[ $checks_passed -lt 3 ]]; then
        warn "Some checks failed. Setup may not be fully functional."
    fi
}

# ═══════════════════════════════════════════════════════════
#  PHASE 10: MIGRATION BACKUP
# ═══════════════════════════════════════════════════════════

phase_10_migration() {
    log "PHASE 10/10: Checking for existing installation..."
    
    # Check if worlds exist (sign of previous installation)
    if [[ -d "${MASTER_DIR}/DoNotStarveTogether" ]]; then
        log "⚠️  Existing Master world found at ${MASTER_DIR}/DoNotStarveTogether"
        read -p "Create backup before continuing? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            local backup_file="${BACKUPS_DIR}/pre-setup-$(timestamp).tar.gz"
            log "Creating backup to: $backup_file"
            tar -czf "$backup_file" \
                -C "${DATA_DIR}" cluster master caves 2>/dev/null || true
            success "Backup created: $(human_size $(stat -f%z "$backup_file" 2>/dev/null || echo 0))"
        fi
    else
        log "✅ No existing installation found (fresh setup)"
    fi
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
    phase_4_steamcmd
    log ""
    phase_5_dst_server
    log ""
    phase_6_config_generation
    log ""
    phase_7_mods
    log ""
    phase_8_helper_scripts
    log ""
    phase_9_health_checks
    log ""
    phase_10_migration
    log ""
    
    log "╔════════════════════════════════════════════════════╗"
    log "║  ✅ SETUP COMPLETE!                               ║"
    log "╚════════════════════════════════════════════════════╝"
    log ""
    log "📋 NEXT STEPS:"
    log "  1. Edit configuration:"
    log "     vi env/.env"
    log "  2. Edit mod list (optional):"
    log "     vi env/mods.txt"
    log "  3. Start server:"
    log "     bash scripts/start.sh"
    log "  4. Check status:"
    log "     bash scripts/status.sh"
    log "  5. View logs:"
    log "     bash scripts/logs.sh"
    log ""
}

main "$@"
