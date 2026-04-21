# 🐳 Docker DST Server Setup Guide

> **📌 Quick Start?** → See [`DOCKER_RUN_GUIDE.md`](DOCKER_RUN_GUIDE.md) for step-by-step instructions to run Docker immediately.

## Which Docker Version?

- **Docker**: 20.10+ (any modern version works)
- **Docker Compose**: 2.0+ (recommended) or 1.29+

```bash
# Check versions
docker --version
docker-compose --version
```

---

## Quick Start (5 Minutes)

### 1. **Configure Environment**

```bash
cd docker/

# Copy template to .env
cp env/.env.template .env

# Edit .env with your settings
nano .env
```

**Required variables in `.env`:**
```bash
DST_CLUSTER_TOKEN=pds-XXXXX...  # Your cluster token from Klei
DST_CLUSTER_NAME=MyServer       # Server name
DST_CLUSTER_PASSWORD=secret     # Join password
DST_MAX_PLAYERS=6               # Player limit
DST_GAME_MODE=endless           # endless, survival, wilderness
```

### 2. **Prepare Mods**

```bash
# Copy mods template
cp env/mods.txt.template env/mods.txt

# Edit to select mods (one mod ID per line)
nano env/mods.txt
```

Example `env/mods.txt`:
```
# Display mods
2798599672    # Display Attack Range
374550642     # Increased Stack Size
1207269058    # Simple Health Bar

# Quality of life
378160973     # Global Positions
351325790     # Geometric Placement
```

### 3. **Start Server**

```bash
# Build image and start containers
docker-compose up -d

# Watch logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 4. **Update Access Lists** (Optional)

```bash
# Edit admin/whitelist/blocklist files
nano env/admins.txt         # Admin Klei user IDs
nano env/whitelist.txt      # Allowed players
nano env/blocklist.txt      # Banned players

# Apply to running server
docker-compose run --rm access-manager
```

---

## How Mods & Config Work in Docker

### **Configuration Flow**

```
Your Host Machine           Docker Container
─────────────────          ─────────────────
env/.env                   → Sourced by entrypoint.sh
env/mods.txt               → Mounted as volume
env/admins.txt             → Mounted as volume
    ↓
data/mods/                 ← Downloaded via SteamCMD
data/cluster/              ← Generated config files
data/master/               ← Master shard config
data/caves/                ← Caves shard config
```

### **Mods: Three Ways to Install**

#### **Option 1: Auto-install via Mods File (Recommended)**

Put mod IDs in `env/mods.txt`:
```bash
2798599672
374550642
1207269058
```

Then update:
```bash
docker-compose run --rm mod-updater
```

✅ Mods downloaded to `data/mods/` automatically
✅ Config generated from `docker/templates/modoverrides.lua.tmpl`

#### **Option 2: Manual Edit Config**

Edit `data/master/modoverrides.lua` directly:
```lua
return {
  ["workshop-2798599672"] = { enabled = true, configuration_options = {} },
  ["workshop-374550642"] = { enabled = true, configuration_options = {} },
}
```

Restart server:
```bash
docker-compose restart dst-master dst-caves
```

#### **Option 3: Add Mods Without Restart**

While server is running:
```bash
# Add to env/mods.txt
echo "2189004162" >> env/mods.txt

# Update mods
docker-compose run --rm mod-updater

# Restart to load new mods
docker-compose restart dst-master dst-caves
```

---

## Configuration Management

### **What Gets Generated on Startup?**

The `entrypoint.sh` script automatically creates:

```
data/
├── cluster/
│   ├── cluster_token.txt      ← From DST_CLUSTER_TOKEN
│   ├── cluster.ini            ← From .env variables
│   ├── adminlist.txt          ← From env/admins.txt
│   ├── whitelist.txt          ← From env/whitelist.txt
│   └── blocklist.txt          ← From env/blocklist.txt
├── master/
│   ├── server.ini             ← Master-specific config
│   ├── modoverrides.lua       ← Active mods (Master)
│   └── worldgenoverride.lua   ← World size/type
├── caves/
│   ├── server.ini             ← Caves-specific config
│   ├── modoverrides.lua       ← Active mods (Caves)
│   └── worldgenoverride.lua   ← Always "DST_CAVE"
└── mods/
    ├── workshop_XXXX/         ← Downloaded mods
    └── dedicated_server_mods_setup.lua  ← Mod load order
```

### **Editing Config**

After initial setup, you can edit files:

**Direct edit (recommended):**
```bash
# Edit .env
nano env/.env

# Restart servers
docker-compose restart dst-master dst-caves
```

**Edit generated files (advanced):**
```bash
# Manually edit cluster.ini
nano data/cluster/cluster.ini

# Restart
docker-compose restart dst-master dst-caves
```

⚠️ **Note:** Files in `data/` are preserved across restarts. `env/` is the source of truth.

---

## Port Configuration

### **Default Ports**

```yaml
Master Server:    10999/UDP
Caves Server:     10998/UDP
Steam Query:      27016/UDP (Master), 27017/UDP (Caves)
Authentication:   8766/UDP (Master), 8767/UDP (Caves)
```

### **Change Ports**

Edit `docker-compose.yml`:
```yaml
ports:
  - "10999:10999/udp"  ← Change left number
  - "10998:10998/udp"  ← Change left number
```

Then restart:
```bash
docker-compose down
docker-compose up -d
```

---

## Daily Operations

### **Check Server Status**

```bash
# Container status
docker-compose ps

# Server logs (all containers)
docker-compose logs -f

# Specific shard
docker-compose logs -f dst-master
docker-compose logs -f dst-caves

# Last 50 lines
docker-compose logs --tail=50 dst-master
```

### **Restart Server**

```bash
# Graceful restart
docker-compose restart dst-master dst-caves

# Full stop/start
docker-compose down
docker-compose up -d

# Rebuild image (after updating mods)
docker-compose up -d --build
```

### **Stop Server**

```bash
# Graceful shutdown
docker-compose down

# Force kill
docker-compose kill
```

### **Backup World Data**

```bash
# Create backup
docker-compose exec dst-master tar -czf /backup/world_$(date +%s).tar.gz \
  /home/dst/.klei/DoNotStarveTogether

# Restore from backup
docker-compose exec dst-master tar -xzf /backup/world_TIMESTAMP.tar.gz -C /
```

---

## Environment Variables (.env Reference)

| Variable | Example | Description |
|----------|---------|-------------|
| `DST_CLUSTER_NAME` | `MyServer` | Cluster name (used for save dirs) |
| `DST_CLUSTER_TOKEN` | `pds-XXXXX...` | **Required** - Token from Klei account |
| `DST_CLUSTER_DISPLAY_NAME` | `My Awesome Server` | Name shown in game browser |
| `DST_CLUSTER_DESCRIPTION` | `Fun cooperative server` | Server description |
| `DST_CLUSTER_PASSWORD` | `secret123` | Join password (empty = public) |
| `DST_GAME_MODE` | `endless` | `endless`, `survival`, or `wilderness` |
| `DST_MAX_PLAYERS` | `6` | Player count limit |
| `DST_WORLD_SIZE` | `small` | `small`, `medium`, or `large` |
| `DST_TICK_RATE` | `15` | Server tick rate (default 15) |

---

## Troubleshooting

### **Ports Already in Use**

```bash
# Find what's using port 10999
lsof -i :10999

# Kill process
kill -9 <PID>

# Or change Docker ports (see Port Configuration above)
```

### **Mods Not Loading**

```bash
# Check logs
docker-compose logs dst-master | grep -i mod

# Verify mod files exist
ls data/mods/workshop_*/

# Regenerate mod config
docker-compose run --rm mod-updater
docker-compose restart dst-master dst-caves
```

### **Server Won't Start**

```bash
# Check full logs
docker-compose logs dst-master

# Verify cluster token
cat env/.env | grep DST_CLUSTER_TOKEN

# Verify binary exists
docker-compose exec dst-master ls /home/dst/dst_server/bin64/
```

### **Container Crashes on Startup**

```bash
# Check for syntax errors in .env
cat env/.env

# Rebuild image
docker-compose up -d --build

# Check logs
docker-compose logs dst-master
```

### **Permission Issues**

```bash
# Reset data directory permissions
sudo chown -R $(whoami):$(whoami) data/

# Try again
docker-compose up -d
```

---

## Container Architecture

### **Three Containers**

1. **dst-master** - Master shard server
   - Handles world generation, save data
   - Coordinates with Caves shard
   
2. **dst-caves** - Caves shard server
   - Separate world, connects to Master
   - Same world save = coordinated gameplay

3. **mod-updater** (on-demand)
   - Downloads mods from Steam Workshop
   - Generates mod override configs
   - Run: `docker-compose run --rm mod-updater`

### **Shared Volumes**

```
data/cluster/        ← Shared by both master & caves
data/master/         ← Master-only config & worlds
data/caves/          ← Caves-only config & worlds  
data/mods/           ← Shared mods folder
```

All changes sync automatically across containers.

---

## Performance Tips

- **Memory**: Docker needs ~1-2GB per shard (default: no limit)
- **CPU**: 2+ cores recommended
- **Disk**: ~2-5GB for game files + mods
- **Network**: Upload-heavy during mod downloads

**Optimize in docker-compose.yml:**
```yaml
services:
  dst-master:
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
```

---

## Comparison: Docker vs Native macOS

| Feature | Docker | macOS Native |
|---------|--------|-------------|
| **Setup time** | 5 min | 10 min |
| **Portability** | Any OS | macOS only |
| **Resource use** | ~15% overhead | None |
| **Updates** | Rebuild image | Re-run setup |
| **Multiple servers** | Easy | Per user |
| **Config management** | Volumes | Files |

---

## Next Steps

1. ✅ Copy `.env.template` → `.env`
2. ✅ Add your cluster token to `.env`
3. ✅ Copy `mods.txt.template` → `env/mods.txt`
4. ✅ Select mods in `env/mods.txt`
5. ✅ Run `docker-compose up -d`
6. ✅ Watch `docker-compose logs -f`
7. ✅ Connect to game and play!

---

## Support

- See `../TROUBLESHOOTING.md` for common issues
- See `../CONFIG_GUIDE.md` for detailed config reference
- See `../README.md` for overall project guide
