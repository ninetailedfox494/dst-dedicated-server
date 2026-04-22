# 🍎 macOS Native DST Server Setup

Complete guide for running Don't Starve Together Dedicated Server natively on macOS.

## Prerequisites

- macOS 10.13+
- Intel or Apple Silicon (M1/M2 via Rosetta)
- Homebrew installed
- Klei cluster token from https://accounts.klei.com/account/game/server

## Quick Start

```bash
# 1. Configure
cp env/.env.template env/.env
nano env/.env  # Add your cluster token

# 2. Setup (one-time, ~10 min)
bash setup_dst_server.sh

# 3. Start
bash scripts/start.sh

# 4. Verify
bash scripts/status.sh
```

---

## Configuration

### Required Settings (env/.env)

```bash
# REQUIRED - Get from https://accounts.klei.com/account/game/server
DST_CLUSTER_TOKEN=pds-XXXXX...
```

### Server Identity

| Variable | Default | Description |
|----------|---------|-------------|
| `DST_CLUSTER_NAME` | `MyDediServer` | Folder name (no spaces) |
| `DST_CLUSTER_DISPLAY_NAME` | `My DST Server` | Name in server browser |
| `DST_CLUSTER_PASSWORD` | (empty) | Join password (empty = public) |
| `DST_CLUSTER_DESCRIPTION` | `A DST Server` | Browser description |

### Gameplay Settings

| Variable | Default | Options |
|----------|---------|---------|
| `DST_GAME_MODE` | `endless` | `endless`, `survival`, `wilderness` |
| `DST_MAX_PLAYERS` | `6` | 1–64 |
| `DST_WORLD_SIZE` | `large` | `small`, `medium`, `large` |
| `DST_PVP` | `false` | `true` or `false` |
| `DST_PAUSE_WHEN_EMPTY` | `true` | Pause with no players |
| `DST_TICK_RATE` | `15` | 10–30 (higher = more CPU) |

### Access Control Files

| File | Purpose |
|------|---------|
| `env/admins.txt` | Admin Klei user IDs (one per line) |
| `env/whitelist.txt` | Allowed players only (empty = all) |
| `env/blocklist.txt` | Banned players |

---

## Mods

### Add Mods

```bash
# Edit mods file
nano env/mods.txt

# Add mod IDs (one per line):
# 2798599672    # Display Attack Range
# 374550642     # Increased Stack Size

# Download and apply
bash scripts/update_mods.sh
bash scripts/stop.sh && bash scripts/start.sh
```

### Find Mod IDs

From Steam Workshop URL:
```
https://steamcommunity.com/sharedfiles/filedetails/?id=2798599672
                                                        ^^^^^^^^^^ ID
```

---

## Helper Scripts

### Server Control

```bash
bash scripts/start.sh         # Start both shards
bash scripts/stop.sh          # Stop all
bash scripts/status.sh        # Check running status
bash scripts/logs.sh          # View logs
bash scripts/logs.sh master   # Master logs only
bash scripts/logs.sh caves    # Caves logs only
```

### Maintenance

```bash
bash scripts/backup.sh        # Backup world
bash scripts/restore.sh       # Restore from backup
bash scripts/update_mods.sh   # Update mods
bash scripts/update_server.sh # Update DST binary
bash scripts/debug.sh         # Debug info
bash scripts/recovery.sh      # Emergency recovery
```

---

## Setup Phases

The setup script runs 10 phases:

1. **Prerequisites** - System detection, Bash version
2. **Directory Structure** - Create folders
3. **Homebrew Dependencies** - Install screen, wget, curl
4. **SteamCMD** - Install Valve's tool
5. **DST Server Binary** - Download game (~5GB)
6. **Configuration** - Generate config files
7. **Mods** - Setup mod system
8. **Helper Scripts** - Validate scripts
9. **Health Checks** - Verify installation
10. **Migration** - Check existing installations

---

## Troubleshooting

### Server Won't Start

```bash
bash scripts/logs.sh
grep CLUSTER_TOKEN env/.env
bash scripts/debug.sh | grep -i port
```

### Port Conflicts

```bash
lsof -i :10999
kill -9 <PID>
bash scripts/start.sh
```

### Server Not Visible in Browser

```bash
bash scripts/status.sh
bash scripts/logs.sh master | grep -E "SteamGameServer_Init|Server registered"
```

Expected: `Port 27016/UDP (Steam Master) is listening`

### Mods Not Loading

```bash
bash scripts/update_mods.sh
bash scripts/logs.sh master | grep -E "Registering Mods|workshop-"
```

### Apple Silicon (M1/M2)

DST runs via Rosetta. If issues:
```bash
softwareupdate --install-rosetta
```

See **[../TROUBLESHOOTING.md](../TROUBLESHOOTING.md)** for more solutions.

---

## Log Locations

```bash
# Live logs
bash scripts/logs.sh master --follow
bash scripts/logs.sh caves --follow

# Log files
~/Documents/Klei/DoNotStarveTogether/<cluster>/Master/server_log.txt
~/Documents/Klei/DoNotStarveTogether/<cluster>/Caves/server_log.txt
```

---

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

### Restore

```bash
bash scripts/restore.sh
# Lists available backups, restores interactively
```

---

## Performance Tips

| Setting | Effect |
|---------|--------|
| `DST_TICK_RATE=10` | Lower CPU usage |
| `DST_WORLD_SIZE=small` | Faster generation |
| Disable heavy mods | Test one at a time |

---

## Directory Structure

```
native-macos/
├── setup_dst_server.sh    # Main setup
├── scripts/               # Helper scripts
│   ├── start.sh
│   ├── stop.sh
│   ├── status.sh
│   └── ...
├── env/                   # Configuration
│   ├── .env
│   ├── mods.txt
│   └── admins.txt
├── data/                  # Server data
│   ├── cluster/
│   ├── master/
│   ├── caves/
│   └── backups/
├── steamcmd/              # SteamCMD
└── dst_server/            # DST binary
```

---

## Config Files (Advanced)

Direct editing (may be overwritten by setup):

| File | Purpose |
|------|---------|
| `data/cluster/cluster.ini` | Cluster settings |
| `data/master/server.ini` | Master network |
| `data/caves/server.ini` | Caves network |
| `data/master/modoverrides.lua` | Mod settings |
| `data/master/worldgenoverride.lua` | World generation |

Always backup before manual edits:
```bash
bash scripts/backup.sh before-editing
```

---

## Quick Reference

```bash
# Essential commands
bash scripts/start.sh        # Start
bash scripts/stop.sh         # Stop
bash scripts/status.sh       # Status
bash scripts/logs.sh         # Logs
bash scripts/backup.sh       # Backup
bash scripts/update_mods.sh  # Update mods
screen -ls                   # List sessions
screen -r dst_master         # Attach to master
```
