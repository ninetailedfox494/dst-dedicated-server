# DST Dedicated Server — macOS Native Setup

Complete standalone setup for running Don't Starve Together Dedicated Server on macOS without Docker.

## Quick Start

```bash
# 1. Run the setup script
bash setup_dst_server.sh

# 2. Configure server (edit as needed)
vi env/.env

# 3. Add mods (optional)
vi env/mods.txt

# 4. Start the server
bash scripts/start.sh

# 5. Check status
bash scripts/status.sh

# 6. View logs
bash scripts/logs.sh
```

## Directory Structure

```
native-macos/
├── setup_dst_server.sh      # Main setup script (10 phases)
├── scripts/                 # Helper scripts
│   ├── _lib.sh             # Shared library
│   ├── start.sh            # Start server
│   ├── stop.sh             # Stop server
│   ├── status.sh           # Check status
│   ├── logs.sh             # View logs
│   ├── backup.sh           # Backup world
│   ├── restore.sh          # Restore world
│   ├── update_mods.sh      # Update mods
│   ├── update_server.sh    # Update DST
│   ├── debug.sh            # Debug info
│   └── recovery.sh         # Recovery mode
├── env/                     # Configuration
│   ├── .env                # Server config (copy from .env.template)
│   ├── .env.template       # Config template
│   ├── mods.txt            # Active mods list
│   ├── mods.txt.template   # Mods template
│   ├── admins.txt          # Admin user IDs
│   ├── whitelist.txt       # Whitelist (optional)
│   └── blocklist.txt       # Blocklist (optional)
├── data/                    # Server data
│   ├── cluster/            # Cluster config
│   ├── master/             # Master server data
│   ├── caves/              # Caves server data
│   ├── mods/               # Mod configuration
│   └── backups/            # World backups
├── steamcmd/               # SteamCMD installation
└── dst_server/             # DST binary
```

## Setup Phases

### PHASE 1: Prerequisites
- macOS system detection
- Bash 4+ requirement (macOS has 3.2, optional upgrade)
- Environment file check

### PHASE 2: Directory Structure
Creates all required folders:
- `data/cluster/`, `data/master/`, `data/caves/`
- `data/mods/`, `data/backups/`
- `steamcmd/`, `env/`, `scripts/`

### PHASE 3: Homebrew Dependencies
Installs required tools:
- `screen` — Run server in background
- `wget` — Download files
- `curl` — HTTP client

### PHASE 4: SteamCMD
Installs Valve's SteamCMD tool for binary management.

### PHASE 5: DST Server Binary
Downloads and validates Don't Starve Together Dedicated Server binary (~5GB).

### PHASE 6: Configuration
Generates config files:
- `cluster.ini` — Cluster settings
- `cluster_token.txt` — Klei auth token
- `server.ini` — Master & Caves server settings
- `worldgenoverride.lua` — World generation

### PHASE 7: Mods
Sets up mod system:
- `dedicated_server_mods_setup.lua` — Mod installation script
- `modoverrides.lua` — Active mods configuration

### PHASE 8: Helper Scripts
Validates helper scripts are ready for use.

### PHASE 9: Health Checks
Verifies:
- DST binary exists and is executable
- Config files are readable
- Required ports (10999, 10998) are available
- Bash version (warning if < 4)

### PHASE 10: Migration
Checks for existing installation and offers migration path.

## Configuration

### Basic Settings (env/.env)

```bash
# Required: Klei Cluster Token
DST_CLUSTER_TOKEN="pds-XXXXXXXX..."  # Get from https://accounts.klei.com

# Server Identity
DST_CLUSTER_NAME="MyDediServer"       # Folder name
DST_CLUSTER_DISPLAY_NAME="Server"     # Shown in server list
DST_CLUSTER_PASSWORD="password"       # Leave empty for public

# Gameplay
DST_GAME_MODE="endless"               # endless, survival, wilderness
DST_MAX_PLAYERS="6"                   # 1-64
DST_WORLD_SIZE="large"                # small, medium, large
DST_PVP="false"                       # true or false
DST_PAUSE_WHEN_EMPTY="true"          # Pause without players

# Network
DST_CONSOLE_ENABLED="true"            # In-game console
DST_TICK_RATE="15"                    # 10-30 (higher = more CPU)
DST_OFFLINE_CLUSTER="false"           # Private server
```

### Admin Access (env/admins.txt)

Add one Klei user ID per line:
```
12345678901234567890
98765432109876543210
```

Get your ID from game logs or the web API.

### Mod Configuration (env/mods.txt)

Add Steam Workshop mod IDs:
```
2078243581
2180980742
2181237068
```

## Helper Scripts

### Server Control

```bash
# Start both Master and Caves
bash scripts/start.sh

# Stop all servers
bash scripts/stop.sh

# Check running status
bash scripts/status.sh

# View live logs
bash scripts/logs.sh
bash scripts/logs.sh master    # Master only
bash scripts/logs.sh caves     # Caves only
```

### Maintenance

```bash
# Backup world
bash scripts/backup.sh

# Restore from backup
bash scripts/restore.sh

# Update mods from Steam Workshop
bash scripts/update_mods.sh

# Update DST binary
bash scripts/update_server.sh

# Debug information
bash scripts/debug.sh

# Emergency recovery
bash scripts/recovery.sh
```

## Troubleshooting

### Server won't start
1. Check logs: `bash scripts/logs.sh`
2. Verify token is valid: `grep CLUSTER_TOKEN env/.env`
3. Check ports are available: `bash scripts/debug.sh | grep -i port`
4. See `../TROUBLESHOOTING.md` for more solutions

### Bash version warning
macOS includes Bash 3.2. Scripts work with it, but consider upgrading:
```bash
brew install bash
chsh -s /usr/local/bin/bash
```

### World won't load
- Delete `data/master/save/` (warning: deletes world data)
- Regenerate with `bash scripts/recovery.sh`

### Port conflicts
Change in `env/.env`:
```bash
# Master port (default 10999)
# Caves port (default 10998, auto-selected)
```

See `../TROUBLESHOOTING.md` for complete guide.

### Server not visible in Browse Games

If direct connect works but server browser cannot find your cluster, check Steam init first:

```bash
bash scripts/status.sh
bash scripts/logs.sh master | grep -E "SteamGameServer_Init|Server registered via geo DNS"
```

Expected:
- `Port 27016/UDP (Steam Master) is listening`
- No `SteamGameServer_Init failed` in logs

If you still see `SteamGameServer_Init failed`:
- Re-run setup to refresh Steam runtime files: `bash setup_dst_server.sh`
- Confirm `dst_server/Library/steamclient.dylib` exists
- Confirm start output shows `Runtime binary: .../dst_server/bin64/dontstarve_dedicated_server_nullrenderer`
- Restart: `bash scripts/stop.sh && bash scripts/start.sh`

### Mods not loading in-game

If the server appears in browser but loads with no mods:

```bash
# Regenerate mod config from env/mods.txt and restart
bash scripts/update_mods.sh

# Verify server sees mods
bash scripts/logs.sh master | grep -E "Registering Mods|No mods registered|workshop-"
```

Expected:
- `Registering Mods:` followed by workshop mod entries
- no `No mods registered`

## Log Tracking

Native helper scripts now read logs from the real Klei runtime path:
- `~/Documents/Klei/DoNotStarveTogether/<cluster>/Master/server_log.txt`
- `~/Documents/Klei/DoNotStarveTogether/<cluster>/Caves/server_log.txt`

Useful commands:

```bash
# Live shard logs
bash scripts/logs.sh master --follow
bash scripts/logs.sh caves --follow

# Steam/browser visibility signals
bash scripts/logs.sh master | grep -E "SteamGameServer_Init|Server registered via geo DNS|Online Server Started"
```

## Performance Tips

1. **CPU**: Increase tick rate in `env/.env` (DST_TICK_RATE=20)
2. **Memory**: Reduce world size (small < medium < large)
3. **Network**: Enable throttling if bandwidth limited
4. **Mods**: Disable heavy mods (test one at a time)

## Game Configuration Files

Generated config files (edit manually if needed):

- `data/cluster/cluster.ini` — Cluster-wide settings
- `data/master/server.ini` — Master server specific
- `data/caves/server.ini` — Caves server specific
- `data/master/worldgenoverride.lua` — Master world generation
- `data/caves/worldgenoverride.lua` — Caves world generation

See `../CONFIG_GUIDE.md` for detailed configuration options.

## Backup & Restore

### Automatic Backup
```bash
bash scripts/backup.sh
# Creates timestamped file in data/backups/
```

### Manual Backup
```bash
tar -czf world_backup_$(date +%s).tar.gz data/master/save data/caves/save
```

### Restore Backup
```bash
bash scripts/restore.sh
# Lists available backups and restores interactively
```

## Git Commits

Each setup phase is a separate commit:
- `Setup script with 10 phases`
- `Shared library for logging and functions`
- `11 helper scripts for management`
- `Configuration templates and files`
- `Comprehensive documentation`

All changes tracked for transparency and rollback capability.

## Support

- **Klei Forum**: https://forums.kleientertainment.com/
- **DST Wiki**: https://dontstarve.fandom.com
- **Steam Discussions**: Community support
- See `../TROUBLESHOOTING.md` for common issues

## License

Don't Starve Together is © Klei Entertainment.
This setup is provided as-is for personal use.
