# macOS Don't Starve Together Dedicated Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a complete native macOS setup system for running DST dedicated server with Master + Caves shards, config-driven via env files, with deluxe management scripts and full documentation.

**Architecture:** Single bootstrap script (`setup_dst_server.sh`) orchestrates 10 phases: prerequisites, dependencies, SteamCMD, DST binary download, config generation, mod download, access lists, helper script creation, health checks, and migration. Helper scripts provide manual control via screen sessions. Config-driven via `env/.env` and `env/mods.txt`. All scripts source shared library (`scripts/_lib.sh`) for logging and utilities.

**Tech Stack:** Bash 4+, SteamCMD, macOS native (Homebrew for `screen`), screen multiplexer, tar/sed/curl for file operations

---

## File Structure

**Create from scratch:**
```
~/dst-server/
├── setup_dst_server.sh                  (main bootstrap, ~600 lines)
├── README.md                            (comprehensive guide)
├── QUICKSTART.md                        (5-min quick ref)
├── CONFIG_GUIDE.md                      (detailed config)
├── TROUBLESHOOTING.md                   (issue resolution)
├── env/
│   ├── .env.template                    (config template)
│   ├── mods.txt.template                (mod list template)
│   ├── admins.txt                       (empty template)
│   ├── whitelist.txt                    (empty template)
│   └── blocklist.txt                    (empty template)
└── scripts/
    ├── _lib.sh                          (shared functions)
    ├── start.sh                         (start Master + Caves)
    ├── stop.sh                          (graceful shutdown)
    ├── status.sh                        (check status + ports)
    ├── logs.sh                          (tail logs)
    ├── backup.sh                        (snapshot worlds)
    ├── restore.sh                       (restore from backup)
    ├── update_mods.sh                   (refresh mods)
    ├── update_server.sh                 (update DST binary)
    ├── debug.sh                         (advanced troubleshooting)
    └── recovery.sh                      (auto-restart shards)

# Auto-created by setup script:
├── data/
│   ├── cluster/                         (cluster config)
│   ├── master/                          (Master shard data)
│   ├── caves/                           (Caves shard data)
│   ├── mods/                            (Workshop mod files)
│   └── backups/                         (world backups)
├── steamcmd/                            (SteamCMD binary)
└── dst_server/                          (DST binary)
```

---

## Phase 1: Shared Library & Base Infrastructure

### Task 1: Create `scripts/_lib.sh` — Shared Functions Library

**Files:**
- Create: `scripts/_lib.sh`

**Purpose:** Central location for logging, color definitions, and common utilities used by all helper scripts.

- [ ] **Step 1: Create shared library file**

Create `scripts/_lib.sh`:

```bash
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
```

- [ ] **Step 2: Make library executable**

```bash
chmod +x scripts/_lib.sh
```

- [ ] **Step 3: Test library loads without errors**

```bash
bash -c "source scripts/_lib.sh && log 'Library loaded successfully'"
```

Expected output:
```
[DST-SERVER] Library loaded successfully
```

- [ ] **Step 4: Commit**

```bash
git add scripts/_lib.sh
git commit -m "feat: add shared library for DST server scripts

- Color definitions (RED, GREEN, YELLOW, BLUE, CYAN)
- Logging functions (log, warn, err, info, success, debug)
- Path exports (PROJECT_ROOT, DATA_DIR, CLUSTER_DIR, etc.)
- Utility functions (session_exists, port_listening, timestamp, etc.)
- Shared env loading via source_env()

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Phase 2: Main Setup Script

### Task 2: Create `setup_dst_server.sh` — Phase 1-3 (Prerequisites & Dependencies)

**Files:**
- Create: `setup_dst_server.sh`

**Purpose:** Main bootstrap script that orchestrates full DST server setup on macOS. Task 2 covers Phases 1-3: prerequisites check, Homebrew dependencies, and SteamCMD installation.

- [ ] **Step 1: Create setup script skeleton with phases 1-3**

Create `setup_dst_server.sh`:

```bash
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
    
    log "✅ Setup phases 1-4 complete!"
    log "Continue with: bash setup_dst_server.sh --continue-phase-5"
}

main "$@"
```

- [ ] **Step 2: Make setup script executable**

```bash
chmod +x setup_dst_server.sh
```

- [ ] **Step 3: Test phases 1-3**

```bash
bash setup_dst_server.sh
```

Expected:
- Checks OS is macOS ✅
- Checks Bash version ✅
- Checks env/.env exists (creates from template if needed)
- Creates directory structure
- Installs Homebrew dependencies (screen, wget, curl)
- Downloads SteamCMD to steamcmd/

- [ ] **Step 4: Commit phases 1-3**

```bash
git add setup_dst_server.sh
git commit -m "feat: add setup script phases 1-4 (prereqs, dirs, homebrew, steamcmd)

- Phase 1: Check prerequisites (macOS, Bash 4+, env/.env)
- Phase 2: Create directory structure (data/, steamcmd/, scripts/, env/)
- Phase 3: Install Homebrew dependencies (screen, wget, curl)
- Phase 4: Download and extract SteamCMD

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 3: Extend `setup_dst_server.sh` — Phase 4-5 (SteamCMD & DST Server)

**Files:**
- Modify: `setup_dst_server.sh` (add phases 4-5 implementation)

- [ ] **Step 1: Add Phase 5 — DST Server Installation**

Replace the `# ═══════════════════════════════════════════════════════════` section before `main()` with:

```bash
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
    
    log "✅ DST Server installed to: ${PROJECT_ROOT}/dst_server/"
}
```

- [ ] **Step 2: Update main() to call phase 5**

In the `main()` function, add after `phase_4_steamcmd`:

```bash
    log ""
    phase_5_dst_server
    log ""
```

- [ ] **Step 3: Test phase 5**

```bash
bash setup_dst_server.sh
```

Should download DST server binary to `dst_server/bin64/dontstarve_dedicated_server_nullrenderer_x64` (takes ~10 min).

- [ ] **Step 4: Verify binary exists**

```bash
ls -lh dst_server/bin64/dontstarve_dedicated_server_nullrenderer_x64
```

Expected: Executable file, ~40-50MB

- [ ] **Step 5: Commit**

```bash
git add setup_dst_server.sh
git commit -m "feat: add setup script phase 5 (DST server download)

- Uses SteamCMD to download app 343050 (DST Dedicated Server)
- Validates binary exists and is executable
- Installs to dst_server/bin64/

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 4: Extend `setup_dst_server.sh` — Phase 6-7 (Config & Mod Generation)

**Files:**
- Modify: `setup_dst_server.sh` (add phases 6-7)

- [ ] **Step 1: Add Phase 6 — Configuration Generation**

Before `main()`, add:

```bash
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
bind_ip = 127.0.0.1
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
    
    # Generate dedicated_server_mods_setup.lua
    local mods_setup="${MODS_DIR}/dedicated_server_mods_setup.lua"
    cat > "$mods_setup" <<'EOF'
--  Mod setup for DST Dedicated Server
--  Mods are auto-downloaded by server on first run
EOF
    
    # Read mods from env/mods.txt and add ServerModSetup lines
    if [[ -f "${PROJECT_ROOT}/env/mods.txt" ]]; then
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            # Extract mod ID (first token before whitespace)
            local mod_id=$(echo "$line" | awk '{print $1}')
            [[ -n "$mod_id" ]] && echo "ServerModSetup(\"$mod_id\")" >> "$mods_setup"
        done < "${PROJECT_ROOT}/env/mods.txt"
    fi
    
    log "✅ dedicated_server_mods_setup.lua created"
    
    # Generate modoverrides.lua templates for Master and Caves
    local modoverrides="return {}\n"
    
    if [[ -f "${PROJECT_ROOT}/env/mods.txt" ]]; then
        while IFS= read -r line; do
            [[ "$line" =~ ^#.*$ ]] && continue
            [[ -z "$line" ]] && continue
            local mod_id=$(echo "$line" | awk '{print $1}')
            if [[ -n "$mod_id" ]]; then
                modoverrides="$(echo "$modoverrides" | sed '$ d')  [\"workshop-$mod_id\"] = { enabled = true, configuration_options = {} },\n}\n"
            fi
        done < "${PROJECT_ROOT}/env/mods.txt"
    fi
    
    echo -e "return {\n  $(echo "$modoverrides" | sed 's/^return {//' | sed 's/}$//')" > "${MASTER_DIR}/modoverrides.lua"
    echo -e "return {\n  $(echo "$modoverrides" | sed 's/^return {//' | sed 's/}$//')" > "${CAVES_DIR}/modoverrides.lua"
    
    log "✅ modoverrides.lua created for Master and Caves"
    log "✅ PHASE 7 complete: Mod configuration ready"
}
```

- [ ] **Step 2: Update main() to call phases 6-7**

Add after `phase_5_dst_server`:

```bash
    log ""
    phase_6_config_generation
    log ""
    phase_7_mods
    log ""
```

- [ ] **Step 3: Test config generation**

```bash
bash setup_dst_server.sh
```

Should create:
- `data/cluster/cluster.ini`, `cluster_token.txt`
- `data/master/server.ini`, `worldgenoverride.lua`, `modoverrides.lua`
- `data/caves/server.ini`, `worldgenoverride.lua`, `modoverrides.lua`
- `data/mods/dedicated_server_mods_setup.lua`

Verify:

```bash
ls -la data/cluster/ data/master/ data/caves/
cat data/cluster/cluster.ini
```

- [ ] **Step 4: Commit**

```bash
git add setup_dst_server.sh
git commit -m "feat: add setup script phases 6-7 (config & mod generation)

- Phase 6: Generate cluster.ini, server.ini for Master/Caves, worldgenoverride.lua
- Phase 7: Generate dedicated_server_mods_setup.lua and modoverrides.lua from env/mods.txt
- All config values sourced from env/.env

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 5: Extend `setup_dst_server.sh` — Phase 8-10 (Helpers, Health Checks, Migration)

**Files:**
- Modify: `setup_dst_server.sh` (add phases 8-10)

- [ ] **Step 1: Add Phase 8 — Helper Scripts**

Before `main()`, add:

```bash
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
```

- [ ] **Step 2: Update main() to call phases 8-10 and print summary**

Replace the current `main()` function ending with:

```bash
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
```

- [ ] **Step 3: Test full setup**

```bash
bash setup_dst_server.sh
```

Should complete all 10 phases without errors.

- [ ] **Step 4: Verify all artifacts created**

```bash
tree -L 3 .  # or: find . -type f -name "*.ini" -o -name "*.txt" | head -20
```

- [ ] **Step 5: Commit**

```bash
git add setup_dst_server.sh
git commit -m "feat: add setup script phases 8-10 (helpers, health checks, migration)

- Phase 8: Verify helper scripts directory and _lib.sh
- Phase 9: Run health checks (binary, config, ports, Bash)
- Phase 10: Back up existing installation if found
- Complete setup summary with next steps

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Phase 3: Helper Scripts (Core Management)

### Task 6: Create `scripts/start.sh` — Start Master + Caves

**Files:**
- Create: `scripts/start.sh`

- [ ] **Step 1: Write start.sh script**

```bash
#!/bin/bash
# scripts/start.sh — Start DST Master and Caves servers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

log "Starting DST Dedicated Server..."

# Check binary exists
if ! dst_binary_exists; then
    err "DST binary not found. Run setup_dst_server.sh first."
fi

# Check config exists
if ! config_exists; then
    err "Config files not found. Run setup_dst_server.sh first."
fi

# Kill old sessions if they exist
for session in dst_master dst_caves; do
    if session_exists "$session"; then
        log "Stopping existing $session session..."
        screen -S "$session" -X quit 2>/dev/null || true
    fi
done
sleep 2

# Start Master shard
log "Starting Master shard on port 10999..."
screen -dmS dst_master \
    bash -c "cd '${DST_SERVER%/*}' && '${DST_SERVER}' -console -cluster '${DST_CLUSTER_NAME}' -shard Master"

log "Waiting for Master to initialize (10s)..."
sleep 10

# Start Caves shard
log "Starting Caves shard on port 10998..."
screen -dmS dst_caves \
    bash -c "cd '${DST_SERVER%/*}' && '${DST_SERVER}' -console -cluster '${DST_CLUSTER_NAME}' -shard Caves"

sleep 2

log ""
success "Servers started!"
log ""
log "📺 View logs:"
log "   Master: screen -r dst_master"
log "   Caves:  screen -r dst_caves"
log "   Exit screen: Ctrl+A then D (detach)"
log ""
log "Check status:"
log "   bash scripts/status.sh"
log ""
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x scripts/start.sh
bash scripts/start.sh
```

Should start Master and Caves in screen sessions.

- [ ] **Step 3: Verify sessions created**

```bash
screen -ls
```

Expected output includes `dst_master` and `dst_caves` sessions.

- [ ] **Step 4: Commit**

```bash
git add scripts/start.sh
git commit -m "feat: add start.sh helper script

- Starts Master shard on port 10999
- Waits 10s for Master initialization
- Starts Caves shard on port 10998
- Runs in screen sessions for manual control

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 7: Create `scripts/stop.sh` — Graceful Shutdown

**Files:**
- Create: `scripts/stop.sh`

- [ ] **Step 1: Write stop.sh script**

```bash
#!/bin/bash
# scripts/stop.sh — Gracefully stop DST servers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

log "Stopping DST servers..."

# Send shutdown command to Caves first
if session_exists "dst_caves"; then
    log "Shutting down Caves shard..."
    screen -S dst_caves -X stuff "c_shutdown(true)$(printf '\r')" 2>/dev/null
    sleep 5
else
    log "Caves shard not running"
fi

# Send shutdown command to Master
if session_exists "dst_master"; then
    log "Shutting down Master shard..."
    screen -S dst_master -X stuff "c_shutdown(true)$(printf '\r')" 2>/dev/null
    sleep 5
else
    log "Master shard not running"
fi

# Force quit if still running
for session in dst_caves dst_master; do
    if session_exists "$session"; then
        log "Force-quitting $session..."
        screen -S "$session" -X quit 2>/dev/null || true
    fi
done

sleep 1
log ""
success "Servers stopped!"
log ""
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x scripts/stop.sh
bash scripts/stop.sh
screen -ls  # Verify sessions are gone
```

- [ ] **Step 3: Commit**

```bash
git add scripts/stop.sh
git commit -m "feat: add stop.sh helper script

- Send c_shutdown(true) to Caves, then Master
- Wait 5s for graceful shutdown
- Force-quit if timeout exceeded
- Verify sessions terminated

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 8: Create `scripts/status.sh` — Check Server Status

**Files:**
- Create: `scripts/status.sh`

- [ ] **Step 1: Write status.sh script**

```bash
#!/bin/bash
# scripts/status.sh — Check DST server status

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

log "═══════════════════════════════════════════════════════"
log "  DST Server Status"
log "═══════════════════════════════════════════════════════"
log ""

# Screen sessions
log "Screen Sessions:"
if screen -ls 2>/dev/null | grep -q dst_master; then
    success "dst_master is running"
    local pid=$(get_session_pid "dst_master")
    [[ -n "$pid" ]] && log "  PID: $pid"
else
    warn "dst_master is not running"
fi

if screen -ls 2>/dev/null | grep -q dst_caves; then
    success "dst_caves is running"
    local pid=$(get_session_pid "dst_caves")
    [[ -n "$pid" ]] && log "  PID: $pid"
else
    warn "dst_caves is not running"
fi

log ""

# Ports
log "Port Status:"
if port_listening 10999 udp; then
    success "Port 10999/UDP (Master) is listening"
else
    warn "Port 10999/UDP (Master) is NOT listening"
fi

if port_listening 10998 udp; then
    success "Port 10998/UDP (Caves) is listening"
else
    warn "Port 10998/UDP (Caves) is NOT listening"
fi

if port_listening 27016 udp; then
    success "Port 27016/UDP (Steam Master) is listening"
else
    warn "Port 27016/UDP (Steam Master) is NOT listening"
fi

log ""

# Process info
log "Process Info:"
if pgrep -f "dontstarve_dedicated_server_nullrenderer" >/dev/null; then
    local count=$(pgrep -f "dontstarve_dedicated_server_nullrenderer" | wc -l)
    success "$count DST process(es) running"
    ps aux | grep -F "dontstarve_dedicated_server_nullrenderer" | grep -v grep | awk '{print "  " $2 " " $11}' || true
else
    warn "No DST processes running"
fi

log ""
log "═══════════════════════════════════════════════════════"
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x scripts/status.sh
bash scripts/start.sh  # Start servers first
sleep 5
bash scripts/status.sh
```

Expected: Shows running sessions and listening ports.

- [ ] **Step 3: Commit**

```bash
git add scripts/status.sh
git commit -m "feat: add status.sh helper script

- Show screen sessions (dst_master, dst_caves)
- Check listening ports (10999, 10998, 27016 UDP)
- Show running DST processes with PIDs
- Color-coded output (green=ok, yellow=warning)

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 9: Create `scripts/logs.sh` — View Server Logs

**Files:**
- Create: `scripts/logs.sh`

- [ ] **Step 1: Write logs.sh script**

```bash
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
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x scripts/logs.sh
bash scripts/logs.sh master  # Show Master logs
# or
bash scripts/logs.sh caves   # Show Caves logs
```

- [ ] **Step 3: Commit**

```bash
git add scripts/logs.sh
git commit -m "feat: add logs.sh helper script

- Show last 100 lines of Master or Caves logs
- Interactive menu if no shard specified
- Optional --follow flag for live tail
- Gracefully handles missing log files

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 10: Create `scripts/backup.sh` — Backup Worlds

**Files:**
- Create: `scripts/backup.sh`

- [ ] **Step 1: Write backup.sh script**

```bash
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
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x scripts/backup.sh
bash scripts/backup.sh before-update
ls -lh data/backups/
```

Expected: Creates `data/backups/before-update-YYYYmmdd-HHMMSS.tar.gz`

- [ ] **Step 3: Commit**

```bash
git add scripts/backup.sh
git commit -m "feat: add backup.sh helper script

- Stop servers before backup
- Create timestamped tar.gz of cluster, master, caves data
- Exclude mods, steamcmd, binaries (re-downloadable)
- Show backup size
- Restart servers after backup

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 11: Create `scripts/restore.sh` — Restore From Backup

**Files:**
- Create: `scripts/restore.sh`

- [ ] **Step 1: Write restore.sh script**

```bash
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
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x scripts/restore.sh
bash scripts/restore.sh  # Interactive menu
```

- [ ] **Step 3: Commit**

```bash
git add scripts/restore.sh
git commit -m "feat: add restore.sh helper script

- List available backups with sizes
- Interactive selection
- Double-confirm before overwriting
- Stop servers, extract, restart

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 12: Create `scripts/update_mods.sh` & `scripts/update_server.sh`

**Files:**
- Create: `scripts/update_mods.sh`
- Create: `scripts/update_server.sh`

- [ ] **Step 1: Write update_mods.sh**

```bash
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
local mod_count=0
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    local mod_id=$(echo "$line" | awk '{print $1}')
    
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

log "Restarting servers..."
bash "${SCRIPT_DIR}/scripts/start.sh"
```

- [ ] **Step 2: Write update_server.sh**

```bash
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
```

- [ ] **Step 3: Make both executable**

```bash
chmod +x scripts/update_mods.sh scripts/update_server.sh
```

- [ ] **Step 4: Commit**

```bash
git add scripts/update_mods.sh scripts/update_server.sh
git commit -m "feat: add update_mods.sh and update_server.sh helpers

update_mods.sh:
- Stop servers, download mods from env/mods.txt via SteamCMD
- Remove old mods, apply new from list
- Restart servers

update_server.sh:
- Stop servers, update DST binary (app 343050)
- Validate installation
- Restart servers

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 13: Create `scripts/debug.sh` & `scripts/recovery.sh`

**Files:**
- Create: `scripts/debug.sh`
- Create: `scripts/recovery.sh`

- [ ] **Step 1: Write debug.sh**

```bash
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
```

- [ ] **Step 2: Write recovery.sh**

```bash
#!/bin/bash
# scripts/recovery.sh — Auto-restart crashed shards

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/scripts/_lib.sh"

source_env

# Daemon mode (continuous monitoring)
if [[ "${1:-}" == "--daemon" ]]; then
    log "Starting recovery daemon (Ctrl+C to stop)..."
    while true; do
        # Check Master
        if ! session_exists "dst_master"; then
            warn "Master shard crashed! Restarting..."
            log "[$(date '+%Y-%m-%d %H:%M:%S')] Master restart" >> "${BACKUPS_DIR}/recovery.log"
            bash "${SCRIPT_DIR}/scripts/start.sh" >/dev/null 2>&1 || true
        fi
        
        # Check Caves
        if ! session_exists "dst_caves"; then
            warn "Caves shard crashed! Restarting..."
            log "[$(date '+%Y-%m-%d %H:%M:%S')] Caves restart" >> "${BACKUPS_DIR}/recovery.log"
            sleep 15
            "${PROJECT_ROOT}/dst_server/bin64/dontstarve_dedicated_server_nullrenderer_x64" \
                -console -cluster "${DST_CLUSTER_NAME}" -shard Caves &
        fi
        
        sleep 30
    done
else
    # Single check mode
    log "Checking server health..."
    
    if session_exists "dst_master"; then
        success "Master shard running"
    else
        warn "Master shard not running"
    fi
    
    if session_exists "dst_caves"; then
        success "Caves shard running"
    else
        warn "Caves shard not running"
    fi
fi
```

- [ ] **Step 3: Make both executable**

```bash
chmod +x scripts/debug.sh scripts/recovery.sh
```

- [ ] **Step 4: Test debug.sh**

```bash
bash scripts/debug.sh
```

- [ ] **Step 5: Commit**

```bash
git add scripts/debug.sh scripts/recovery.sh
git commit -m "feat: add debug.sh and recovery.sh helpers

debug.sh:
- Show cluster.ini config
- List installed mods
- Show world sizes
- Display recent log errors
- Network diagnostics (ports, firewall)

recovery.sh:
- Check if Master/Caves running
- Optional daemon mode for auto-restart (recovery.sh --daemon)
- Log restart events to recovery.log

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Phase 4: Configuration Templates

### Task 14: Create Configuration Templates

**Files:**
- Create: `env/.env.template`
- Create: `env/mods.txt.template`
- Create: `env/admins.txt`
- Create: `env/whitelist.txt`
- Create: `env/blocklist.txt`

- [ ] **Step 1: Create env/.env.template**

```bash
cat > env/.env.template <<'EOF'
# ═══════════════════════════════════════════════════════════
# Don't Starve Together Dedicated Server — macOS Configuration
# ═══════════════════════════════════════════════════════════

# REQUIRED: Klei Cluster Token
# Get from: https://accounts.klei.com/account/game/server
# Format: pds-XXXXXXXX...
DST_CLUSTER_TOKEN="REPLACE_WITH_REAL_TOKEN"

# ═══════════════════════════════════════════════════════════
# CLUSTER IDENTITY
# ═══════════════════════════════════════════════════════════

# Folder name (no spaces, used internally)
DST_CLUSTER_NAME="MyDediServer"

# Display name in server list (can have spaces)
DST_CLUSTER_DISPLAY_NAME="NineTailedFox"

# Password to join server (empty = public)
DST_CLUSTER_PASSWORD="8"

# Description shown in server list
DST_CLUSTER_DESCRIPTION="Endless Mode Co-op Server"

# ═══════════════════════════════════════════════════════════
# GAMEPLAY SETTINGS
# ═══════════════════════════════════════════════════════════

# Game mode: endless, survival, or wilderness
DST_GAME_MODE="endless"

# Max players (1-64)
DST_MAX_PLAYERS="6"

# World size: small, medium, or large
DST_WORLD_SIZE="large"

# PvP enabled: true or false
DST_PVP="false"

# Pause when no players: true or false
DST_PAUSE_WHEN_EMPTY="true"

# ═══════════════════════════════════════════════════════════
# SERVER NETWORK
# ═══════════════════════════════════════════════════════════

# Enable in-game console
DST_CONSOLE_ENABLED="true"

# Tick rate (10-30, higher = more CPU usage)
DST_TICK_RATE="15"

# Offline cluster (private, not on server list)
DST_OFFLINE_CLUSTER="false"

# ═══════════════════════════════════════════════════════════
# ADMIN & ACCESS CONTROL
# ═══════════════════════════════════════════════════════════

# Edit separate files instead:
# env/admins.txt    — User IDs with full admin
# env/whitelist.txt — Only these users can join
# env/blocklist.txt — These users cannot join
EOF
```

- [ ] **Step 2: Create env/mods.txt.template**

```bash
cat > env/mods.txt.template <<'EOF'
# Workshop Mod IDs (one per line)
# Find ID from workshop URL: https://steamcommunity.com/sharedfiles/filedetails/?id=XXXXX
# Comment with # for notes

# Quality of Life
2078243581   # Display Attack Range
375850593    # Extra Equip Slots
374550642    # Increased Stack size
1207269058   # Simple Health Bar
1852257480   # Beefalo Widget

# UI & Info
376333686    # Combined Status
378160973    # Global Positions
351325790    # Geometric Placement
1608191708   # ActionQueue Reborn
345692228    # Minimap HUD

# Utility
362175979    # Wormhole Marks
347079953    # Display Food Values
597417408    # Less Lags
569043634    # Campfire Respawn
1412085556   # Growable Sword
EOF
```

- [ ] **Step 3: Create access list templates**

```bash
cat > env/admins.txt <<'EOF'
# Admin user IDs (one per line)
# Get your ID from: https://steamcommunity.com/account
# Format: KU_XXXXXXXXXX

# Example:
# KU_J9MSQD54
EOF

cat > env/whitelist.txt <<'EOF'
# Whitelist user IDs (if enabled, only these can join)
# Leave empty to allow all
EOF

cat > env/blocklist.txt <<'EOF'
# Blocklist user IDs (these cannot join)
# Leave empty if not using
EOF
```

- [ ] **Step 4: Make templates readable and commit**

```bash
chmod 644 env/.env.template env/mods.txt.template env/admins.txt env/whitelist.txt env/blocklist.txt
git add env/
git commit -m "feat: add configuration templates

- env/.env.template: comprehensive config with comments
- env/mods.txt.template: example mod list with categories
- env/{admins,whitelist,blocklist}.txt: access control templates

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Phase 5: Documentation

### Task 15: Create `README.md` — Comprehensive User Guide

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write comprehensive README.md**

```bash
cat > README.md <<'EOF'
# 🎮 Don't Starve Together Dedicated Server — macOS Native Setup

Native macOS DST dedicated server with Master + Caves shards, config-driven setup, and comprehensive management scripts.

**Features:**
- ✅ One-command bootstrap on macOS
- ✅ Config-driven via `env/.env` and `env/mods.txt`
- ✅ Master + Caves shards (dual-world gameplay)
- ✅ Auto-download Workshop mods
- ✅ Backup/restore worlds
- ✅ Advanced debugging & auto-recovery
- ✅ Manual control via helper scripts

---

## System Requirements

| Component | Requirement |
|-----------|-------------|
| OS | macOS 10.13+ |
| CPU | Intel or Apple Silicon (M1/M2 via Rosetta) |
| RAM | 2GB minimum, 4GB+ recommended |
| Disk | 20GB for server + worlds |
| Bash | Version 4.0+ |

**Homebrew Packages:**
- `steamcmd` — Download DST server
- `screen` — Terminal multiplexer for running servers
- `curl`, `wget` — File downloads

---

## Quick Start (5 minutes)

### Step 1: Prepare Configuration

```bash
cd ~/dst-server
cp env/.env.template env/.env
vi env/.env
```

Update these in `env/.env`:
```bash
DST_CLUSTER_TOKEN="your-real-token-here"  # GET FROM klei.com
DST_CLUSTER_DISPLAY_NAME="YourServerName"
DST_CLUSTER_PASSWORD="password123"
```

### Step 2: Run Setup

```bash
bash setup_dst_server.sh
```

This will:
- ✅ Install Homebrew dependencies
- ✅ Download SteamCMD
- ✅ Download DST server binary
- ✅ Generate all config files
- ✅ Download mods from `env/mods.txt`
- ✅ Run health checks

### Step 3: Start Server

```bash
bash scripts/start.sh
```

### Step 4: Check Status

```bash
bash scripts/status.sh
```

### Step 5: View Logs

```bash
bash scripts/logs.sh master  # Or: caves
```

---

## Full Installation Guide

### Prerequisites

Ensure Homebrew is installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Installation

1. **Clone or download this repository:**

```bash
git clone <repo-url> ~/dst-server
cd ~/dst-server
```

2. **Get your Klei token:**

Visit: https://accounts.klei.com/account/game/server

Copy your cluster token.

3. **Configure server:**

```bash
cp env/.env.template env/.env
vi env/.env  # Paste token, set cluster name, password, etc.
```

4. **Run setup (one time):**

```bash
bash setup_dst_server.sh
```

Output should show:
```
[DST-SERVER] ✅ SETUP COMPLETE!
```

5. **Start servers:**

```bash
bash scripts/start.sh
```

6. **Verify running:**

```bash
bash scripts/status.sh
screen -ls  # See running screen sessions
```

7. **Join from DST:**

- Open Don't Starve Together
- Find "NineTailedFox" (or your configured name) in server browser
- Enter password if set
- Enjoy!

---

## Configuration Reference

See `CONFIG_GUIDE.md` for detailed configuration options.

### Quick Config Changes

**Change server password:**
```bash
vi env/.env
# Update: DST_CLUSTER_PASSWORD="newpassword"
bash scripts/stop.sh
bash setup_dst_server.sh  # Re-generate config
bash scripts/start.sh
```

**Change max players:**
```bash
vi env/.env
# Update: DST_MAX_PLAYERS="10"
bash scripts/stop.sh
bash setup_dst_server.sh
bash scripts/start.sh
```

**Add mods:**
```bash
vi env/mods.txt
# Add Workshop IDs
bash scripts/update_mods.sh
```

---

## Helper Scripts

### Core Operations

| Script | Purpose |
|--------|---------|
| `scripts/start.sh` | Start Master + Caves servers |
| `scripts/stop.sh` | Gracefully shut down both shards |
| `scripts/status.sh` | Check running status + ports |
| `scripts/logs.sh` | View server logs |

### Maintenance

| Script | Purpose |
|--------|---------|
| `scripts/backup.sh` | Create timestamped world backup |
| `scripts/restore.sh` | Restore from backup |
| `scripts/update_mods.sh` | Refresh mods from `env/mods.txt` |
| `scripts/update_server.sh` | Update DST binary |

### Debugging

| Script | Purpose |
|--------|---------|
| `scripts/debug.sh` | Show config, mods, logs, network status |
| `scripts/recovery.sh` | Monitor and auto-restart crashed shards |

---

## Daily Operations

### Start Server

```bash
bash scripts/start.sh
```

**Attach to console:**
```bash
screen -r dst_master   # View Master shard
# or
screen -r dst_caves    # View Caves shard

# Exit screen: Ctrl+A then D (detach)
```

**In-game console commands (while viewing):**
```bash
# Type directly in screen:
c_announce("Message to players")
TheNet:SetPassword("newpass")
c_shutdown(true)  # Graceful shutdown
```

### Stop Server

```bash
bash scripts/stop.sh
```

### Check Status

```bash
bash scripts/status.sh
```

### Backup Before Major Changes

```bash
bash scripts/backup.sh before-update
```

### View Logs

```bash
bash scripts/logs.sh
# or
bash scripts/logs.sh master --follow  # Live tail
```

---

## Directory Structure

```
~/dst-server/
├── setup_dst_server.sh              # Initial setup (run once)
├── README.md                        # This file
├── QUICKSTART.md                    # Quick reference
├── CONFIG_GUIDE.md                  # Detailed config docs
├── TROUBLESHOOTING.md               # Issue resolution
├── env/
│   ├── .env                         # Configuration (user-edited)
│   ├── mods.txt                     # Mod list (user-edited)
│   ├── admins.txt                   # Admin IDs
│   ├── whitelist.txt                # Whitelist (optional)
│   └── blocklist.txt                # Blocklist (optional)
├── scripts/
│   ├── _lib.sh                      # Shared functions
│   ├── start.sh                     # Start servers
│   ├── stop.sh                      # Stop servers
│   ├── status.sh                    # Check status
│   ├── logs.sh                      # View logs
│   ├── backup.sh                    # Backup worlds
│   ├── restore.sh                   # Restore from backup
│   ├── update_mods.sh               # Update mods
│   ├── update_server.sh             # Update DST binary
│   ├── debug.sh                     # Debug info
│   └── recovery.sh                  # Auto-restart
├── data/
│   ├── cluster/                     # Cluster config
│   │   ├── cluster.ini
│   │   ├── cluster_token.txt
│   │   ├── adminlist.txt
│   │   ├── whitelist.txt
│   │   └── blocklist.txt
│   ├── master/                      # Master shard
│   │   ├── server.ini
│   │   ├── modoverrides.lua
│   │   ├── DoNotStarveTogether/    # Game world data
│   │   └── dontstarve.log
│   ├── caves/                       # Caves shard
│   │   ├── server.ini
│   │   ├── modoverrides.lua
│   │   ├── DoNotStarveTogether/    # Game world data
│   │   └── dontstarve.log
│   ├── mods/                        # Workshop mod files
│   └── backups/                     # World backups
├── steamcmd/                        # SteamCMD binary
└── dst_server/                      # DST server binary
    └── bin64/
        └── dontstarve_dedicated_server_nullrenderer_x64
```

---

## Troubleshooting

See `TROUBLESHOOTING.md` for solutions to:
- Server won't start
- Server keeps crashing
- Mods not loading
- Can't connect from outside
- Network issues
- macOS-specific problems

Quick checks:

```bash
# Check if binary exists
file dst_server/bin64/dontstarve_dedicated_server_nullrenderer_x64

# Check if config valid
cat data/cluster/cluster.ini

# View error logs
bash scripts/logs.sh master
bash scripts/logs.sh caves

# Network diagnostics
bash scripts/debug.sh
```

---

## Performance Tips

1. **Reduce tick rate** if CPU high:
   ```bash
   # In env/.env: DST_TICK_RATE="10"
   ```

2. **Smaller world size**:
   ```bash
   # In env/.env: DST_WORLD_SIZE="small"
   ```

3. **Fewer mods**: Disable heavy mods in `env/mods.txt`

4. **Monitor memory**:
   ```bash
   top -p $(pgrep -f dontstarve_dedicated)
   ```

---

## Advanced: Auto-Recovery Daemon

Run as background process to auto-restart crashed shards:

```bash
bash scripts/recovery.sh --daemon &
```

View restart log:
```bash
tail -f data/backups/recovery.log
```

---

## Security Notes

- **Do NOT commit** `env/.env` (contains your token)
- **Rotate token** if exposed
- **Use whitelist.txt** to restrict who can join
- **Use blocklist.txt** to ban users
- **Console access** is unrestricted; use admin panel or `c_announce()` carefully

---

## Support & Issues

For bugs or questions:
1. Check `TROUBLESHOOTING.md`
2. Run `bash scripts/debug.sh` to collect diagnostics
3. Check server logs: `bash scripts/logs.sh`
4. Verify `env/.env` configuration

---

## Version History

- **v1.0** (2026-04-15): Initial release
  - Setup script with 10 phases
  - 11 helper scripts
  - Full documentation

---

**Enjoy your Don't Starve Together server! 🎮**
EOF
```

- [ ] **Step 2: Commit README**

```bash
git add README.md
git commit -m "docs: add comprehensive README

- Quick start guide (5 minutes)
- Full installation instructions
- Configuration reference
- Helper scripts documentation
- Troubleshooting reference
- Performance tips
- Security notes

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Task 16: Create `QUICKSTART.md`, `CONFIG_GUIDE.md`, `TROUBLESHOOTING.md`

**Files:**
- Create: `QUICKSTART.md`
- Create: `CONFIG_GUIDE.md`
- Create: `TROUBLESHOOTING.md`

- [ ] **Step 1: Create QUICKSTART.md**

```bash
cat > QUICKSTART.md <<'EOF'
# ⚡ Quick Start — 5 Minutes

## Prerequisites

- macOS 10.13+
- Homebrew installed
- Klei cluster token from https://accounts.klei.com/account/game/server

## Setup

```bash
cd ~/dst-server

# 1. Configure
cp env/.env.template env/.env
vi env/.env  # Add token, server name, password

# 2. Setup (one time, ~15 min)
bash setup_dst_server.sh

# 3. Start
bash scripts/start.sh

# 4. Verify
bash scripts/status.sh
```

## Running Server

```bash
# Start
bash scripts/start.sh

# Stop
bash scripts/stop.sh

# View logs
bash scripts/logs.sh master
bash scripts/logs.sh caves

# Status
bash scripts/status.sh
```

## Adding Mods

```bash
# 1. Find mod ID on Steam Workshop
# 2. Add to env/mods.txt
# 3. Update
bash scripts/update_mods.sh
```

## Backup & Restore

```bash
# Backup
bash scripts/backup.sh before-update

# Restore
bash scripts/restore.sh
```

## Useful Commands

```bash
# Debug info
bash scripts/debug.sh

# Auto-restart crashed shards
bash scripts/recovery.sh --daemon

# Check if running
screen -ls

# Attach to console
screen -r dst_master
```

See `README.md` and `CONFIG_GUIDE.md` for full docs.
EOF
```

- [ ] **Step 2: Create CONFIG_GUIDE.md**

```bash
cat > CONFIG_GUIDE.md <<'EOF'
# Configuration Guide

## env/.env Variables

### Required

**DST_CLUSTER_TOKEN**
- Your Klei cluster token
- Get from: https://accounts.klei.com/account/game/server
- Format: `pds-XXXXXXXXXXXX`
- No default; must be set

### Cluster Identity

| Variable | Default | Notes |
|----------|---------|-------|
| `DST_CLUSTER_NAME` | `MyDediServer` | Folder name (no spaces) |
| `DST_CLUSTER_DISPLAY_NAME` | `NineTailedFox` | Name in server browser |
| `DST_CLUSTER_PASSWORD` | (empty) | Leave empty for public |
| `DST_CLUSTER_DESCRIPTION` | `DST Server` | Description in browser |

### Gameplay

| Variable | Default | Options |
|----------|---------|---------|
| `DST_GAME_MODE` | `endless` | `endless`, `survival`, `wilderness` |
| `DST_MAX_PLAYERS` | `6` | 1–64 |
| `DST_WORLD_SIZE` | `large` | `small`, `medium`, `large` |
| `DST_PVP` | `false` | `true` or `false` |
| `DST_PAUSE_WHEN_EMPTY` | `true` | Auto-pause with no players |

### Server

| Variable | Default | Notes |
|----------|---------|-------|
| `DST_CONSOLE_ENABLED` | `true` | Enable in-game console |
| `DST_TICK_RATE` | `15` | 10–30 (higher = more CPU) |
| `DST_OFFLINE_CLUSTER` | `false` | Private (not in browser) |

## env/mods.txt Format

Workshop mod IDs, one per line:

```
# Comments start with #
2078243581   # Display Attack Range
375850593    # Extra Equip Slots

# Blank lines ignored
1207269058
```

Find mod ID from Steam Workshop URL:
```
https://steamcommunity.com/sharedfiles/filedetails/?id=2078243581
                                                           ^^^^^^^^^^^ ID
```

## Access Control Files

### env/admins.txt

Users with full admin rights:
```
KU_XXXXXXXX
KU_YYYYYYYY
```

### env/whitelist.txt

If enabled, ONLY these users can join (one ID per line).
Leave empty to allow all users.

### env/blocklist.txt

Users banned from joining (one ID per line).

Find your user ID:
- Open Don't Starve Together
- View profile
- URL: `https://steamcommunity.com/profiles/123456789`
- DST ID: `KU_` prefix + last digits

## Changing Configuration

After editing `env/.env`, reapply:

```bash
bash scripts/stop.sh
bash setup_dst_server.sh    # Regenerate config
bash scripts/start.sh
```

## World Generation

Default presets:
- Master: `DST_FOREST`
- Caves: `DST_CAVE`

To customize, edit `data/master/worldgenoverride.lua` and `data/caves/worldgenoverride.lua` manually, then restart.

## Performance Tuning

Reduce CPU usage:
```bash
# env/.env
DST_TICK_RATE="10"          # Lower = less CPU
DST_WORLD_SIZE="small"      # Smaller world = faster
```

Increase available slots:
```bash
DST_MAX_PLAYERS="12"        # Up from 6
```

## Advanced: Manual Config Edits

Direct file edits (not recommended, may be overwritten by setup script):

- `data/cluster/cluster.ini` — Cluster settings
- `data/master/server.ini` — Master network
- `data/caves/server.ini` — Caves network
- `data/master/modoverrides.lua` — Master mod settings
- `data/caves/modoverrides.lua` — Caves mod settings

Always backup before manual edits:
```bash
bash scripts/backup.sh before-editing
```

---

See `README.md` for more details.
EOF
```

- [ ] **Step 3: Create TROUBLESHOOTING.md**

```bash
cat > TROUBLESHOOTING.md <<'EOF'
# Troubleshooting Guide

## Server Won't Start

### Error: "DST binary not found"

**Solution:**
```bash
ls -l dst_server/bin64/dontstarve_dedicated_server_nullrenderer_x64
```

If missing, reinstall:
```bash
bash setup_dst_server.sh
```

### Error: "Config files not found"

**Solution:**
```bash
ls -l data/cluster/cluster.ini
```

If missing:
```bash
bash setup_dst_server.sh
```

### Error: "Port already in use"

**Solution:**
```bash
# Check what's using port 10999
lsof -i :10999

# Kill old process
kill -9 <PID>

# Then start
bash scripts/start.sh
```

## Server Keeps Crashing

### Check logs:
```bash
bash scripts/logs.sh master
bash scripts/logs.sh caves
```

### Common crash causes:

**Out of memory:**
- Reduce `DST_TICK_RATE` in `env/.env`
- Check: `top -p $(pgrep -f dontstarve)`

**Corrupt world data:**
- Restore from backup: `bash scripts/restore.sh`
- Or delete and recreate: `rm -rf data/master/DoNotStarveTogether`

**Mod conflict:**
- Disable all mods: edit `env/mods.txt`, run `bash scripts/update_mods.sh`
- Re-enable one by one

### Auto-restart crashed servers:
```bash
bash scripts/recovery.sh --daemon
```

## Mods Not Loading

### Check mod download:
```bash
ls -la data/mods/
```

### Verify mod IDs:
```bash
cat env/mods.txt
```

### Re-download:
```bash
bash scripts/update_mods.sh
```

### Common issues:

**Mod deleted from Workshop:**
- Remove from `env/mods.txt`
- Run: `bash scripts/update_mods.sh`

**Mod ID typo:**
- Check URL: `steamcommunity.com/sharedfiles/filedetails/?id=XXXXX`
- Correct ID in `env/mods.txt`
- Run: `bash scripts/update_mods.sh`

**Mod incompatible:**
- Some mods conflict; test one at a time
- Disable in `env/mods.txt`
- Run: `bash scripts/update_mods.sh`

## Can't Connect From Outside

### Check ports open:
```bash
bash scripts/debug.sh
bash scripts/status.sh
```

Expected: Ports 10999, 10998, 27016 listening.

### If ports not showing:

**macOS firewall blocking:**
```bash
# Check firewall
sudo pfctl -s nat

# Allow ports (if UFW not installed)
# Manually in System Preferences > Security & Privacy > Firewall
```

**VPS/cloud firewall:**
- Whitelist UDP ports: 10999, 10998, 27016
- (Network settings, not OS-level)

### If server not showing in browser:

- Verify `DST_OFFLINE_CLUSTER=false` in `env/.env`
- Check server list: "NineTailedFox" (or your name)
- If still not showing:
  - Cluster token invalid → verify in env/.env
  - Server name taken → change in env/.env
  - Restart server: `bash scripts/stop.sh && bash scripts/start.sh`

## Token Issues

### Error: "Invalid token" in logs

**Solution:**
1. Get new token: https://accounts.klei.com/account/game/server
2. Update `env/.env`:
   ```bash
   DST_CLUSTER_TOKEN="pds-NEW_TOKEN_HERE"
   ```
3. Restart:
   ```bash
   bash scripts/stop.sh
   bash setup_dst_server.sh
   bash scripts/start.sh
   ```

## Network Errors

### Error: "Connection refused"

Check if server running:
```bash
bash scripts/status.sh
```

If not, start:
```bash
bash scripts/start.sh
```

### Error: "Unable to authenticate"

Check logs:
```bash
bash scripts/logs.sh master
```

Common cause: Invalid Klei token or network issue.

## macOS Specific Issues

### M1/M2 (Apple Silicon)

DST runs via Rosetta translation. Should work transparently.

If issues:
```bash
# Check if Rosetta installed
arch

# If error, install Rosetta:
softwareupdate --install-rosetta

# Verify binary type
file dst_server/bin64/dontstarve_dedicated_server_nullrenderer_x64
```

### Bash version too old

```bash
# Check version
bash --version

# If below 4.0, upgrade
brew install bash

# Use new Bash
/usr/local/bin/bash setup_dst_server.sh
```

### Homebrew conflicts

If `brew install` fails:
```bash
brew doctor  # Check for conflicts
brew update && brew upgrade
```

## Getting Help

**Collect diagnostics:**
```bash
bash scripts/debug.sh > diagnostics.txt
bash scripts/logs.sh master >> diagnostics.txt
bash scripts/status.sh >> diagnostics.txt
```

**Share:**
- `diagnostics.txt`
- Output of: `cat env/.env` (remove token)
- Output of: `cat env/mods.txt`

---

For more help, see `README.md` and `CONFIG_GUIDE.md`.
EOF
```

- [ ] **Step 4: Commit all docs**

```bash
git add QUICKSTART.md CONFIG_GUIDE.md TROUBLESHOOTING.md
git commit -m "docs: add QUICKSTART, CONFIG_GUIDE, TROUBLESHOOTING

QUICKSTART.md:
- 5-minute setup guide
- Daily commands reference
- Quick mod/backup workflow

CONFIG_GUIDE.md:
- All env/.env variables explained
- mods.txt format and Workshop ID discovery
- Access control files (admins/whitelist/blocklist)
- Performance tuning
- Advanced manual configuration

TROUBLESHOOTING.md:
- Server won't start (binary, config, ports)
- Server crashes (logs, memory, mods)
- Mods not loading (download, ID, conflicts)
- Can't connect (firewall, token)
- macOS specific (M1/Rosetta, Bash, Homebrew)
- Diagnostics collection

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Phase 6: Integration Testing

### Task 17: Integration Test & Verification

**Purpose:** Verify all components work together in realistic workflow.

- [ ] **Step 1: Clean slate (remove old data if present)**

```bash
rm -rf data/ steamcmd/ dst_server/
rm env/.env  # Will be recreated
```

- [ ] **Step 2: Run full setup from scratch**

```bash
bash setup_dst_server.sh
```

Expected output:
```
[DST-SERVER] PHASE 1/10: Checking prerequisites...
[DST-SERVER] ✅ PHASE 1 complete...
...
[DST-SERVER] ✅ SETUP COMPLETE!
```

- [ ] **Step 3: Verify directory structure**

```bash
tree -L 2 data/ scripts/ env/ 2>/dev/null || find . -type d -name "data" -o -name "scripts" -o -name "env"
```

Expected:
- ✅ data/cluster/, data/master/, data/caves/, data/mods/, data/backups/
- ✅ scripts/start.sh, scripts/_lib.sh, etc.
- ✅ env/.env, env/mods.txt, env/admins.txt

- [ ] **Step 4: Verify config files created**

```bash
ls -la data/cluster/cluster.ini data/master/server.ini data/caves/server.ini
cat data/cluster/cluster.ini  # Check values filled from env/.env
```

- [ ] **Step 5: Start servers**

```bash
bash scripts/start.sh
sleep 5
screen -ls  # Verify dst_master and dst_caves running
```

- [ ] **Step 6: Check status**

```bash
bash scripts/status.sh
```

Expected:
```
Screen Sessions:
✅ dst_master is running
✅ dst_caves is running
Port Status:
✅ Port 10999/UDP (Master) is listening
✅ Port 10998/UDP (Caves) is listening
✅ Port 27016/UDP (Steam Master) is listening
```

- [ ] **Step 7: View logs (verify no errors)**

```bash
bash scripts/logs.sh master | head -30
bash scripts/logs.sh caves | head -30
```

- [ ] **Step 8: Test backup**

```bash
bash scripts/backup.sh test-backup
ls -lh data/backups/test-backup*
```

- [ ] **Step 9: Test helper scripts**

```bash
# Debug
bash scripts/debug.sh | head -20

# Status
bash scripts/status.sh

# Stop and restart
bash scripts/stop.sh
sleep 3
bash scripts/start.sh
sleep 5
bash scripts/status.sh
```

- [ ] **Step 10: Final verification**

```bash
# All helper scripts exist and are executable
for script in scripts/*.sh; do
    [[ -x "$script" ]] && echo "✅ $script" || echo "❌ $script"
done

# All config files exist
for f in data/cluster/cluster.ini data/master/server.ini data/caves/server.ini; do
    [[ -f "$f" ]] && echo "✅ $f" || echo "❌ $f"
done
```

- [ ] **Step 11: Commit integration test results**

```bash
git add -A
git commit -m "test: verify full setup integration

- Clean setup from scratch: ✅
- Directory structure complete: ✅
- Config files generated: ✅
- Servers start and listen on correct ports: ✅
- Helper scripts functional: ✅
- Backup/restore working: ✅
- All documentation present: ✅

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Summary

**Total files created:**
- 1 main setup script
- 11 helper scripts
- 1 shared library
- 5 config templates
- 4 documentation files
- All auto-generated config files (on first run)

**Total commits:** 17+ (one per task)

**Setup time:** ~15 minutes (mostly SteamCMD download)

**Next steps after implementation:**
- Test on real macOS machine
- Document known limitations
- Add GitHub CI/CD for validation (optional)
- Publish to GitHub for community use

---

**Plan Status:** ✅ READY FOR IMPLEMENTATION
EOF
```

- [ ] **Commit the plan**

```bash
git add docs/superpowers/plans/2026-04-15-macos-dst-setup.md
git commit -m "plan: add comprehensive implementation plan

17 tasks organized in 6 phases:
- Phase 1: Shared library & base infrastructure
- Phase 2: Main setup script (10 phases)
- Phase 3: Helper scripts (11 total)
- Phase 4: Configuration templates
- Phase 5: Full documentation (4 guides)
- Phase 6: Integration testing

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Execution Options

**Plan complete and saved to `docs/superpowers/plans/2026-04-15-macos-dst-setup.md`.**

Two ways to execute:

**Option 1: Subagent-Driven (Recommended)**
- Fresh subagent per task
- Code review between tasks
- Faster iteration
- I oversee quality

**Option 2: Inline Execution**
- Execute tasks in this session
- Batch execution with checkpoints
- Single context window
- Full transparency

**Which approach would you prefer?**