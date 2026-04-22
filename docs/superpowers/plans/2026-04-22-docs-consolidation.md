# Documentation Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate 29 markdown files into 5 clean, non-duplicating documentation files with clear hierarchy.

**Architecture:** Delete redundant files, merge content into 4 target files (README.md, docker/README.md, native-macos/README.md, TROUBLESHOOTING.md). Each platform guide becomes self-contained with embedded configuration.

**Tech Stack:** Markdown, Git

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Rewrite | `README.md` | Project overview, comparison table, path selector |
| Rewrite | `docker/README.md` | Complete Docker guide (merged from 3 sources) |
| Rewrite | `native-macos/README.md` | Complete macOS guide (merged from 2 sources) |
| Update | `TROUBLESHOOTING.md` | Unified troubleshooting for both platforms |
| Delete | `QUICKSTART.md` | Content merged into platform READMEs |
| Delete | `DOCUMENTATION_INDEX.md` | Redundant navigation |
| Delete | `DOCKER_GUIDE.md` | Merged into docker/README.md |
| Delete | `DOCKER_RUN_GUIDE.md` | Merged into docker/README.md |
| Delete | `SETUP_COMPARISON.md` | Comparison moved to root README |
| Delete | `CONFIG_GUIDE.md` | Config embedded in platform READMEs |
| Delete | `native-macos/INDEX.md` | Redundant with README |
| Delete | `native-macos/BUG_TRACKING.md` | Historical, no longer needed |
| Delete | `native-macos/CHANGELOG.md` | Historical, no longer needed |

---

## Task 1: Rewrite Root README.md

**Files:**
- Rewrite: `README.md`

- [ ] **Step 1: Create new README.md content**

Replace entire `README.md` with:

```markdown
# 🎮 Don't Starve Together Dedicated Server

Run a DST dedicated server on **macOS (native)** or **any platform (Docker)**.

## Which Setup?

| Question | Docker | macOS Native |
|----------|--------|--------------|
| Want cross-platform? | ✅ Yes | ❌ macOS only |
| Have Docker installed? | ✅ Use it | — |
| Want smallest footprint? | ~15% overhead | ✅ Zero overhead |
| Setup time | ~5 min | ~10 min |
| Multiple servers? | ✅ Easy | Manual |

**Not sure?** Start with Docker if you have it installed; otherwise use macOS native.

## Quick Start

### Docker (Recommended for Portability)

```bash
cd docker
cp env/.env.template env/.env
# Edit env/.env with your cluster token
docker-compose up -d
```

👉 **[Complete Docker Guide](docker/README.md)**

### macOS Native (Recommended for macOS)

```bash
cd native-macos
cp env/.env.template env/.env
# Edit env/.env with your cluster token
bash setup_dst_server.sh
bash scripts/start.sh
```

👉 **[Complete macOS Guide](native-macos/README.md)**

## Prerequisites

- **Klei cluster token** from https://accounts.klei.com/account/game/server
- **Docker** (for Docker setup): 20.10+, Docker Compose 2.0+
- **macOS** (for native setup): 10.13+, Homebrew

## Features

Both setups include:
- ✅ Master + Caves shards (dual-world gameplay)
- ✅ Config-driven via environment files
- ✅ Auto-download Steam Workshop mods
- ✅ Backup/restore worlds
- ✅ Status monitoring & logs
- ✅ Helper scripts

## Project Structure

```
docker-dst-server/
├── docker/                 # Docker setup
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── README.md           # Docker guide
├── native-macos/           # macOS native setup
│   ├── setup_dst_server.sh
│   ├── scripts/
│   └── README.md           # macOS guide
├── README.md               # This file
└── TROUBLESHOOTING.md      # Problem solving
```

## Troubleshooting

See **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for solutions to common issues.

## Support

- **Klei Forum**: https://forums.kleientertainment.com/
- **DST Wiki**: https://dontstarve.fandom.com

---

**Enjoy your Don't Starve Together server! 🎮**
```

- [ ] **Step 2: Verify README renders correctly**

Run: `cat README.md | head -50`
Expected: Clean markdown with no broken links

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: rewrite root README with clean hierarchy

- Simplified comparison table
- Clear path selector (Docker vs macOS)
- Removed duplication
- Links to platform-specific guides

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 2: Rewrite docker/README.md (Complete Docker Guide)

**Files:**
- Rewrite: `docker/README.md`

- [ ] **Step 1: Create consolidated docker/README.md**

Replace entire `docker/README.md` with merged content from DOCKER_GUIDE.md, DOCKER_RUN_GUIDE.md, and CONFIG_GUIDE.md:

```markdown
# 🐳 Docker DST Server Setup

Complete guide for running Don't Starve Together Dedicated Server with Docker.

## Prerequisites

```bash
docker --version          # 20.10+
docker-compose --version  # 2.0+
```

## Quick Start (5 Minutes)

```bash
# 1. Initialize environment
bash setup/init_docker_env.sh

# 2. Configure
nano env/.env             # Add your cluster token

# 3. Start
docker-compose up -d

# 4. Watch logs
docker-compose logs -f
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
| `DST_WORLD_SIZE` | `small` | `small`, `medium`, `large` |
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

### Add Mods via mods.txt (Recommended)

```bash
# Edit mods file
nano env/mods.txt

# Add mod IDs (one per line):
# 2798599672    # Display Attack Range
# 374550642     # Increased Stack Size

# Download and apply
docker-compose run --rm mod-updater
docker-compose restart dst-master dst-caves
```

### Find Mod IDs

From Steam Workshop URL:
```
https://steamcommunity.com/sharedfiles/filedetails/?id=2798599672
                                                        ^^^^^^^^^^ ID
```

---

## Daily Operations

### Start/Stop/Restart

```bash
docker-compose up -d              # Start
docker-compose stop               # Stop (keeps data)
docker-compose down               # Stop and remove containers
docker-compose restart            # Restart
docker-compose restart dst-master # Restart one shard
```

### View Logs

```bash
docker-compose logs -f            # All services
docker-compose logs -f dst-master # Master only
docker-compose logs --tail=50     # Last 50 lines
```

### Check Status

```bash
docker-compose ps                 # Container status
docker stats dst-master dst-caves # Resource usage
```

### Backup World

```bash
# Create backup
docker-compose exec dst-master tar -czf /tmp/backup.tar.gz \
  /home/dst/.klei/DoNotStarveTogether

# Copy to host
docker cp $(docker-compose ps -q dst-master):/tmp/backup.tar.gz ./backups/
```

### Update Mods

```bash
docker-compose run --rm mod-updater
docker-compose restart dst-master dst-caves
```

---

## Ports

| Port | Service |
|------|---------|
| 10999/UDP | Master Server |
| 10998/UDP | Caves Server |
| 27016/UDP | Steam Query (Master) |
| 27017/UDP | Steam Query (Caves) |

### Change Ports

Edit `docker-compose.yml`:
```yaml
ports:
  - "11999:10999/udp"  # Change left number
```

---

## Container Architecture

**Three containers:**
1. **dst-master** - Master shard (world gen, saves)
2. **dst-caves** - Caves shard (connects to master)
3. **mod-updater** - On-demand mod downloads

**Shared volumes:**
```
data/cluster/   # Shared config
data/master/    # Master shard data
data/caves/     # Caves shard data
data/mods/      # Downloaded mods
```

---

## Troubleshooting

### Port Already in Use

```bash
lsof -i :10999
kill -9 <PID>
# Or change ports in docker-compose.yml
```

### Mods Not Loading

```bash
docker-compose logs dst-master | grep -i mod
ls data/mods/workshop_*/
docker-compose run --rm mod-updater
docker-compose restart
```

### Container Won't Start

```bash
docker-compose logs dst-master
cat env/.env | grep DST_CLUSTER_TOKEN
docker-compose up -d --build
```

### Permission Issues

```bash
sudo chown -R $(whoami):$(whoami) data/
docker-compose up -d
```

See **[../TROUBLESHOOTING.md](../TROUBLESHOOTING.md)** for more solutions.

---

## Performance Tips

- **Memory**: 1-2GB per shard recommended
- **CPU**: 2+ cores
- **Disk**: 2-5GB for game + mods

Add limits in `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      memory: 2G
```

---

## File Structure After Setup

```
docker/
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh
├── env/
│   ├── .env              # Your config
│   ├── mods.txt          # Mod list
│   └── admins.txt        # Admin users
├── data/
│   ├── cluster/          # Generated configs
│   ├── master/           # Master shard
│   ├── caves/            # Caves shard
│   └── mods/             # Downloaded mods
└── setup/
    └── init_docker_env.sh
```

---

## Quick Reference

```bash
# Essential commands
docker-compose up -d                 # Start
docker-compose down                  # Stop
docker-compose ps                    # Status
docker-compose logs -f               # Logs
docker-compose restart               # Restart
docker-compose run --rm mod-updater  # Update mods
docker-compose exec dst-master bash  # Shell access
```
```

- [ ] **Step 2: Verify docker/README.md renders correctly**

Run: `wc -l docker/README.md`
Expected: ~250-300 lines

- [ ] **Step 3: Commit**

```bash
git add docker/README.md
git commit -m "docs: consolidate Docker guide into single README

Merged content from:
- DOCKER_GUIDE.md
- DOCKER_RUN_GUIDE.md
- CONFIG_GUIDE.md (Docker parts)

Self-contained guide with config, operations, troubleshooting.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 3: Rewrite native-macos/README.md (Complete macOS Guide)

**Files:**
- Rewrite: `native-macos/README.md`

- [ ] **Step 1: Create consolidated native-macos/README.md**

Replace entire `native-macos/README.md` with merged content:

```markdown
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
```

- [ ] **Step 2: Verify native-macos/README.md renders correctly**

Run: `wc -l native-macos/README.md`
Expected: ~280-320 lines

- [ ] **Step 3: Commit**

```bash
git add native-macos/README.md
git commit -m "docs: consolidate macOS guide into single README

Merged content from:
- Previous README.md
- CONFIG_GUIDE.md (macOS parts)
- QUICKSTART.md (macOS parts)

Self-contained guide with config, scripts, troubleshooting.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 4: Update TROUBLESHOOTING.md (Unified)

**Files:**
- Update: `TROUBLESHOOTING.md`

- [ ] **Step 1: Add platform labels to TROUBLESHOOTING.md**

Edit `TROUBLESHOOTING.md` to add clear platform labels. Add Docker section after existing content:

```markdown
## Docker-Specific Issues

### Container Won't Start

```bash
docker-compose logs dst-master
cat env/.env | grep DST_CLUSTER_TOKEN
docker-compose up -d --build
```

### Permission Issues (Docker)

```bash
sudo chown -R $(whoami):$(whoami) data/
docker-compose up -d
```

### Out of Memory (Docker)

Increase Docker memory in Docker Desktop settings, or add limits:
```yaml
# docker-compose.yml
deploy:
  resources:
    limits:
      memory: 2G
```
```

- [ ] **Step 2: Verify TROUBLESHOOTING.md**

Run: `grep -c "##" TROUBLESHOOTING.md`
Expected: 10+ section headers

- [ ] **Step 3: Commit**

```bash
git add TROUBLESHOOTING.md
git commit -m "docs: add Docker troubleshooting section

Unified troubleshooting for both platforms.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 5: Delete Redundant Files

**Files:**
- Delete: `QUICKSTART.md`
- Delete: `DOCUMENTATION_INDEX.md`
- Delete: `DOCKER_GUIDE.md`
- Delete: `DOCKER_RUN_GUIDE.md`
- Delete: `SETUP_COMPARISON.md`
- Delete: `CONFIG_GUIDE.md`
- Delete: `native-macos/INDEX.md`
- Delete: `native-macos/BUG_TRACKING.md`
- Delete: `native-macos/CHANGELOG.md`

- [ ] **Step 1: Delete redundant root files**

```bash
rm QUICKSTART.md
rm DOCUMENTATION_INDEX.md
rm DOCKER_GUIDE.md
rm DOCKER_RUN_GUIDE.md
rm SETUP_COMPARISON.md
rm CONFIG_GUIDE.md
```

- [ ] **Step 2: Delete redundant native-macos files**

```bash
rm native-macos/INDEX.md
rm native-macos/BUG_TRACKING.md
rm native-macos/CHANGELOG.md
```

- [ ] **Step 3: Verify deletions**

Run: `ls *.md`
Expected: Only `README.md` and `TROUBLESHOOTING.md`

Run: `ls native-macos/*.md`
Expected: Only `README.md`

- [ ] **Step 4: Commit deletions**

```bash
git add -A
git commit -m "docs: remove redundant documentation files

Deleted (content merged into platform READMEs):
- QUICKSTART.md
- DOCUMENTATION_INDEX.md
- DOCKER_GUIDE.md
- DOCKER_RUN_GUIDE.md
- SETUP_COMPARISON.md
- CONFIG_GUIDE.md
- native-macos/INDEX.md
- native-macos/BUG_TRACKING.md
- native-macos/CHANGELOG.md

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Task 6: Final Verification

**Files:**
- Verify: All remaining .md files

- [ ] **Step 1: List remaining documentation**

```bash
find . -name "*.md" -not -path "./docs/superpowers/*" | sort
```

Expected output:
```
./docker/README.md
./docker/setup/README.md
./native-macos/README.md
./README.md
./TROUBLESHOOTING.md
```

- [ ] **Step 2: Verify no broken links**

```bash
grep -r "\[.*\](.*\.md)" *.md docker/*.md native-macos/*.md 2>/dev/null | grep -v "docs/superpowers"
```

Check each link exists.

- [ ] **Step 3: Final commit (if any fixes needed)**

```bash
git status
# If changes needed:
git add -A
git commit -m "docs: fix broken links after consolidation

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

---

## Summary

| Before | After |
|--------|-------|
| 29 markdown files | 5 core docs |
| Duplicated setup 4x | Single source per platform |
| 6+ entry points | 1 entry point (README) |
| Config scattered | Config embedded in guides |
| ~1500 lines duplication | Zero duplication |
