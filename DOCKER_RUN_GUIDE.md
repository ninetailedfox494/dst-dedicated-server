# 🐳 Docker Run Guide - DST Dedicated Server

**Updated**: April 2024  
**Status**: Ready to run with Docker

---

## Prerequisites

```bash
# Check Docker is installed
docker --version      # Should be 20.10+
docker-compose --version  # Should be 2.0+

# If docker-compose is missing:
brew install docker-compose
```

---

## Step-by-Step: Getting Docker Running

### 1. Navigate to Docker Directory

```bash
cd docker/
```

### 2. Prepare Environment Configuration

**Create directory structure** (if not exists):
```bash
mkdir -p env
mkdir -p data/{cluster,master,caves,mods}
```

**Create `.env` file** from your settings:
```bash
# Option A: Copy from native-macOS template
cp ../native-macos/env/.env.template ./env/.env

# Option B: Create from scratch
cat > env/.env << 'EOF'
# ========== REQUIRED ==========
DST_CLUSTER_TOKEN=pds-YOUR_TOKEN_HERE

# ========== SERVER IDENTITY ==========
DST_CLUSTER_NAME=MyDSTServer
DST_CLUSTER_DISPLAY_NAME=My DST Server
DST_CLUSTER_DESCRIPTION=A Don't Starve Together Server
DST_CLUSTER_PASSWORD=

# ========== GAMEPLAY SETTINGS ==========
DST_GAME_MODE=endless              # endless, survival, wilderness
DST_MAX_PLAYERS=6
DST_WORLD_SIZE=small               # small, medium, large
DST_TICK_RATE=15

# ========== OPTIONAL FEATURES ==========
DST_PAUSE_WHEN_EMPTY=true
DST_PVP=false
DST_VOTE_ENABLED=true
EOF
```

**Edit your settings**:
```bash
nano env/.env
# Update DST_CLUSTER_TOKEN and other settings as needed
```

### 3. Prepare Mod List (Optional)

**Create mods file**:
```bash
# Copy from template
cp ../native-macos/env/mods.txt.template ./env/mods.txt

# Or create with default mods:
cat > env/mods.txt << 'EOF'
# Popular DST Mods (one ID per line)
2798599672    # Display Attack Range
374550642     # Increased Stack Size
1207269058    # Simple Health Bar
2477889104    # Global Positions
378160973     # Geometric Placement
351325790     # Mineable Trees & Rocks
362175979     # Emerald Tools
597417408     # All Biomes
569043634     # Faster Crafting
2189004162    # Stone Walls
1852257480    # Breezie Sleeper
EOF
```

### 4. Verify docker-compose Configuration

```bash
# Test the compose file is valid
docker-compose config

# Expected output: Full YAML configuration (no errors)
```

### 5. Build & Start Containers

```bash
# Build image and start services
docker-compose up -d

# Watch initialization logs
docker-compose logs -f dst-master

# Wait for message: "Starting new server..."
# Press Ctrl+C when ready to continue
```

### 6. Verify Servers Are Running

```bash
# Check container status
docker-compose ps

# Expected output:
# NAME                COMMAND             STATUS
# dst-master          "/home/dst/docker..  Up 2 minutes
# dst-caves           "/home/dst/docker..  Up 2 minutes
```

### 7. Check Server Logs

```bash
# View all logs
docker-compose logs -f

# View specific service
docker-compose logs -f dst-master
docker-compose logs -f dst-caves

# Search for specific messages
docker-compose logs | grep "saving world"
```

---

## Common Operations

### Start Server

```bash
# Start all services
docker-compose up -d

# Start specific service
docker-compose up -d dst-master
docker-compose up -d dst-caves
```

### Stop Server

```bash
# Stop all services (keeps data)
docker-compose stop

# Stop specific service
docker-compose stop dst-master

# Remove containers (keeps data in volumes)
docker-compose down
```

### Restart Server

```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart dst-master
docker-compose restart dst-caves
```

### View Status

```bash
# Container status
docker-compose ps

# Container resource usage
docker stats dst-master dst-caves
```

### View Logs

```bash
# Real-time logs from all services
docker-compose logs -f

# Last 50 lines
docker-compose logs --tail=50

# From last 30 minutes
docker-compose logs --since=30m

# Logs with timestamps
docker-compose logs --timestamps
```

---

## Managing Mods

### Add New Mod

```bash
# 1. Add mod ID to mods file
echo "2189004162" >> env/mods.txt

# 2. Download and configure
docker-compose run --rm mod-updater

# 3. Restart to load mods
docker-compose restart dst-master dst-caves
```

### Update All Mods

```bash
docker-compose run --rm mod-updater
docker-compose restart dst-master dst-caves
```

### Edit Mod Config (While Running)

```bash
# Edit mod config in running container
docker-compose exec dst-master nano /home/dst/.klei/DoNotStarveTogether/MyDSTServer/Master/modoverrides.lua

# Restart to apply changes
docker-compose restart dst-master dst-caves
```

### Copy Mod Config to Host

```bash
# Export master mods config
docker-compose exec dst-master cat /home/dst/.klei/DoNotStarveTogether/MyDSTServer/Master/modoverrides.lua > data/master/modoverrides.lua

# Or for caves
docker-compose exec dst-caves cat /home/dst/.klei/DoNotStarveTogether/MyDSTServer/Caves/modoverrides.lua > data/caves/modoverrides.lua
```

---

## Managing Access Lists

### Set Admins

```bash
cat > env/admins.txt << 'EOF'
KleiUserID1
KleiUserID2
EOF

docker-compose run --rm access-manager
docker-compose restart
```

### Set Whitelist

```bash
cat > env/whitelist.txt << 'EOF'
KleiUserID1
KleiUserID2
EOF

docker-compose run --rm access-manager
docker-compose restart
```

### Set Blocklist

```bash
cat > env/blocklist.txt << 'EOF'
BannedUserID1
BannedUserID2
EOF

docker-compose run --rm access-manager
docker-compose restart
```

---

## Backup & Restore

### Backup World

```bash
# Create backup of world data
docker-compose exec dst-master tar -czf /tmp/dst_backup_$(date +%s).tar.gz \
  /home/dst/.klei/DoNotStarveTogether

# Copy to host
docker cp $(docker-compose ps -q dst-master):/tmp/dst_backup_*.tar.gz ./backups/
```

### List Volumes

```bash
# See what data is in each volume
docker volume ls | grep dst

# Inspect volume data
docker volume inspect docker_data_master
```

### Access Container Shell

```bash
# Open bash in running container
docker-compose exec dst-master bash

# Run commands in container
docker-compose exec dst-master ls -la /home/dst/.klei/DoNotStarveTogether
```

---

## Troubleshooting

### Fix: Docker Build Error ("/docker": not found)

If you see this error during `docker-compose up -d`:
```
ERROR: failed to build: failed to solve: failed to compute cache key: 
failed to calculate checksum of ref: "/docker": not found
```

**This has been fixed!** The Dockerfile COPY path issue has been corrected.

**What was the issue?**
- Old: `COPY --chown=dst:dst docker /home/dst/docker`
- Fixed: `COPY --chown=dst:dst . /home/dst/docker`

**Solution:**
```bash
# Pull latest Dockerfile
git pull origin main

# Rebuild
docker-compose up -d --build
```

---

### Containers Not Starting

```bash
# Check full logs
docker-compose logs

# Look for error messages, common issues:
# - DST_CLUSTER_TOKEN not set
# - DST_CLUSTER_NAME not set
# - Port conflicts (10999, 10998 already in use)
```

### Fix: Missing Token

```bash
# Edit .env
nano env/.env

# Set DST_CLUSTER_TOKEN
# Save and restart
docker-compose down
docker-compose up -d
```

### Fix: Port Already in Use

```bash
# Option 1: Change ports in docker-compose.yml
nano docker-compose.yml
# Change ports: "10999:10999/udp" to "11999:10999/udp"
docker-compose restart

# Option 2: Stop conflicting service
lsof -i :10999
kill -9 <PID>
docker-compose restart
```

### Fix: Out of Memory

```bash
# Increase Docker memory in Docker Desktop settings
# Or limit container memory in docker-compose.yml:
# mem_limit: 2g
```

### Check Container Health

```bash
# See health status
docker-compose ps

# View health checks
docker inspect $(docker-compose ps -q dst-master) | grep -A 5 "Health"

# Manually run health check
docker-compose exec dst-master pgrep -f dontstarve_dedicated_server_nullrenderer_x64
```

---

## Advanced: Docker Compose Commands

### Build Image

```bash
# Build Docker image from Dockerfile
docker-compose build

# Rebuild without cache
docker-compose build --no-cache
```

### Scale Services (Not Recommended)

```bash
# Docker Compose doesn't support scaling DST, but you can run multiple instances:
docker-compose -f docker-compose.yml -p dst1 up -d
docker-compose -f docker-compose.yml -p dst2 -e DST_CLUSTER_NAME=MyServer2 up -d
```

### Export Data

```bash
# Export cluster data
docker-compose exec dst-master tar -czf /tmp/cluster.tar.gz \
  /home/dst/.klei/DoNotStarveTogether

# Copy to host
docker cp $(docker-compose ps -q dst-master):/tmp/cluster.tar.gz ./
```

### Remove Everything (Start Fresh)

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (CAREFUL - deletes all data!)
docker-compose down -v

# Remove image
docker rmi dst-dedicated:latest
```

---

## File Structure After Running

```
docker/
├── docker-compose.yml          # Service definitions
├── Dockerfile                  # Image definition
├── entrypoint.sh              # Startup script
├── env/
│   ├── .env                   # Your configuration
│   ├── mods.txt               # Mod list
│   ├── admins.txt             # Admin users
│   ├── whitelist.txt          # Allowed players
│   └── blocklist.txt          # Banned players
├── data/
│   ├── cluster/               # Cluster config (generated)
│   │   ├── cluster.ini
│   │   ├── cluster_token.txt
│   │   └── ...
│   ├── master/                # Master shard data (generated)
│   │   ├── server.ini
│   │   ├── modoverrides.lua
│   │   ├── worldgenoverride.lua
│   │   └── ...
│   ├── caves/                 # Caves shard data (generated)
│   │   ├── server.ini
│   │   ├── modoverrides.lua
│   │   └── ...
│   └── mods/                  # Downloaded mods
│       ├── dedicated_server_mods_setup.lua
│       ├── workshop-2798599672/
│       └── ...
└── templates/
    └── modoverrides.lua.tmpl  # Mod config template
```

---

## Comparing: Docker vs Native macOS

| Feature | Docker | Native macOS |
|---------|--------|--------------|
| Setup Time | 5 min | 10 min |
| Resource Overhead | ~10-15% | 0% |
| Multi-server Setup | Easy | Complex |
| Direct File Access | Via volumes | Direct |
| Cross-platform | ✅ Yes (Linux/Win) | ❌ macOS only |
| Performance | 90-95% native | 100% native |
| Isolation | Container | Direct |

---

## Next Steps

1. ✅ Set up `.env` with your cluster token
2. ✅ Run `docker-compose up -d`
3. ✅ Check logs with `docker-compose logs -f`
4. ✅ Verify with `docker-compose ps`
5. ✅ Join your server in DST and test
6. ✅ Add mods as desired
7. ✅ Configure access lists (admins, whitelist, etc.)

---

## Quick Reference

```bash
# Essential commands
docker-compose up -d              # Start
docker-compose down               # Stop
docker-compose ps                 # Status
docker-compose logs -f            # Logs
docker-compose restart            # Restart
docker-compose run --rm mod-updater  # Update mods

# Debugging
docker-compose config             # Validate config
docker-compose exec dst-master bash  # Access container
docker volume ls                  # List volumes
docker stats                      # CPU/Memory usage
```

---

## Support

For issues:
- Check `../TROUBLESHOOTING.md` for detailed help
- Review `../CONFIG_GUIDE.md` for configuration options
- See `../SETUP_COMPARISON.md` for Docker vs Native comparison

Happy hosting! 🎮
