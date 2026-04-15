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
