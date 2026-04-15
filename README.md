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
│   ├── master/                      # Master shard
│   ├── caves/                       # Caves shard
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
