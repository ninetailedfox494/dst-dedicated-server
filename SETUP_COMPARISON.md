# 🎮 Setup Comparison: Docker vs Native macOS

## Quick Decision Table

| Question | Docker ✅ | macOS Native ✅ |
|----------|-----------|-----------------|
| **Want fastest setup?** | 5 minutes | 10 minutes |
| **Using macOS?** | Yes | Yes |
| **Want multiple servers on same machine?** | Yes (easy) | Yes (complex) |
| **Want cross-platform (Linux/Windows)?** | Yes | No |
| **Already have Docker installed?** | Yes | - |
| **Want smallest resource footprint?** | No | Yes |
| **Prefer containerized isolation?** | Yes | No |

---

## Setup Flow

### **Docker Setup**
```
docker/
├── docker-compose.yml      ← Start here
├── Dockerfile             ← Builds image automatically
├── entrypoint.sh          ← Runs on container startup
├── .env                   ← Copy from template
├── env/mods.txt          ← List mods (one per line)
└── data/                 ← Auto-created, volumes mount here
    ├── cluster/          ← Config files
    ├── master/           ← Master shard
    ├── caves/            ← Caves shard
    └── mods/             ← Downloaded mods
```

**Steps:**
1. `cp env/.env.template env/.env`
2. Edit `env/.env` (add cluster token)
3. `cp env/mods.txt.template env/mods.txt`
4. Edit `env/mods.txt` (add mod IDs)
5. `docker-compose up -d`
6. Done! ✅

---

### **Native macOS Setup**
```
native-macos/
├── setup_dst_server.sh      ← Start here
├── scripts/
│   ├── _lib.sh              ← Shared library
│   ├── start.sh             ← Start servers
│   ├── stop.sh              ← Stop servers
│   ├── status.sh            ← Check status
│   ├── logs.sh              ← View logs
│   ├── backup.sh            ← Backup world
│   ├── update_mods.sh       ← Update mods
│   └── ... 7 more helpers
├── env/
│   ├── .env                 ← Configuration
│   └── mods.txt             ← Mod list
└── data/                    ← Auto-created by setup
    ├── cluster/
    ├── master/
    ├── caves/
    └── mods/
```

**Steps:**
1. `bash setup_dst_server.sh` (installs everything)
2. Edit `env/.env` (add cluster token)
3. Edit `env/mods.txt` (add mod IDs)
4. `bash scripts/start.sh`
5. Done! ✅

---

## Feature Comparison

### **Mods & Config**

#### Docker
- **Mods file:** `env/mods.txt` (read on each container start)
- **Config source:** `env/.env` variables
- **Config generated:** In `data/` volumes
- **Update mods:** `docker-compose run --rm mod-updater`
- **Restart required:** Yes, `docker-compose restart`

```bash
# Add mod
echo "2798599672" >> env/mods.txt
docker-compose run --rm mod-updater
docker-compose restart dst-master dst-caves
```

#### Native macOS
- **Mods file:** `env/mods.txt` (read once at setup)
- **Config source:** `env/.env` variables
- **Config stored:** In `data/` directly
- **Update mods:** `bash scripts/update_mods.sh`
- **Restart required:** Yes, `bash scripts/stop.sh && bash scripts/start.sh`

```bash
# Add mod
echo "2798599672" >> env/mods.txt
bash scripts/update_mods.sh
bash scripts/stop.sh && bash scripts/start.sh
```

---

## How Mods & Config Load

### **Docker Flow**

```
entrypoint.sh (runs in container)
    ↓
1. Source env/.env
    ↓
2. Create config files in data/cluster, data/master, data/caves
    ↓
3. Copy modoverrides.lua.tmpl to data/master & data/caves
    ↓
4. Generate dedicated_server_mods_setup.lua from env/mods.txt
    ↓
5. Mount volumes to container
    ↓
6. Start DST server with -cluster flag
    ↓
Server reads config from volume-mounted data/
```

**Key:** Everything happens in container on startup. Host files are read-only inputs.

### **Native macOS Flow**

```
setup_dst_server.sh (Phase 10)
    ↓
1. Source env/.env
    ↓
2. Create config files in data/cluster, data/master, data/caves
    ↓
3. Copy modoverrides.lua template to data/
    ↓
4. Generate dedicated_server_mods_setup.lua from env/mods.txt
    ↓
5. scripts/start.sh
    ↓
6. Start DST server directly with -cluster flag
    ↓
Server reads config from data/
```

**Key:** Setup runs once. Server reads config files each time.

---

## Configuration Variables

Both setups support the same environment variables:

```bash
# Required
DST_CLUSTER_TOKEN=pds-XXXXX...

# Server identity
DST_CLUSTER_NAME=MyServer
DST_CLUSTER_DISPLAY_NAME=My Awesome Server
DST_CLUSTER_DESCRIPTION=Description here
DST_CLUSTER_PASSWORD=secret         # Empty = public

# Gameplay
DST_GAME_MODE=endless               # endless, survival, wilderness
DST_MAX_PLAYERS=6
DST_WORLD_SIZE=small                # small, medium, large
DST_TICK_RATE=15

# Optional
DST_PAUSE_WHEN_EMPTY=true
DST_PVP=false
DST_VOTE_ENABLED=true
```

---

## Mod Installation: Side-by-Side

### **Add Single Mod**

**Docker:**
```bash
# 1. Add to mods file
echo "2798599672" >> env/mods.txt

# 2. Download & configure
docker-compose run --rm mod-updater

# 3. Restart
docker-compose restart dst-master dst-caves
```

**macOS:**
```bash
# 1. Add to mods file
echo "2798599672" >> env/mods.txt

# 2. Download & configure
bash scripts/update_mods.sh

# 3. Restart
bash scripts/stop.sh
bash scripts/start.sh
```

### **Edit Mod Config While Running**

**Docker:**
```bash
# Edit mod config in running container
docker-compose exec dst-master nano /home/dst/.klei/DoNotStarveTogether/MyServer/Master/modoverrides.lua

# Restart to apply
docker-compose restart dst-master dst-caves
```

**macOS:**
```bash
# Edit mod config on disk
nano data/master/modoverrides.lua

# Restart
bash scripts/stop.sh
bash scripts/start.sh
```

---

## Accessing Server Data

### **Docker**

```bash
# View logs
docker-compose logs -f dst-master

# Access config files (via volume mount on host)
cat data/master/modoverrides.lua
cat data/cluster/cluster.ini

# Backup
docker-compose exec dst-master tar -czf backup.tar.gz \
  /home/dst/.klei/DoNotStarveTogether
```

### **macOS**

```bash
# View logs
bash scripts/logs.sh --follow

# Access config files (direct)
cat data/master/modoverrides.lua
cat data/cluster/cluster.ini

# Backup
bash scripts/backup.sh
```

---

## Resource Usage

### **Docker**
- **Container per shard:** 2 containers (master + caves)
- **Memory per shard:** ~800MB (default: unlimited)
- **Overhead:** ~10-15% vs native
- **Disk:** Shared across containers, ~2-5GB total

### **macOS Native**
- **Screen sessions:** 2 (dst_master + dst_caves)
- **Memory per shard:** ~800MB
- **Overhead:** 0% (native)
- **Disk:** ~2-5GB total

---

## When to Use Each

### **Choose Docker if:**
- ✅ You might run on Linux/Windows later
- ✅ You want container isolation
- ✅ You want multiple servers on same machine
- ✅ You prefer immutable infrastructure
- ✅ You're familiar with Docker
- ✅ You want automated image updates

### **Choose Native macOS if:**
- ✅ You only need simple setup
- ✅ You want native performance
- ✅ You're not familiar with Docker
- ✅ You want direct file access
- ✅ You prefer minimal dependencies
- ✅ You want easiest troubleshooting

---

## Quick Reference: Common Tasks

| Task | Docker | macOS |
|------|--------|-------|
| Start server | `docker-compose up -d` | `bash scripts/start.sh` |
| Stop server | `docker-compose down` | `bash scripts/stop.sh` |
| View logs | `docker-compose logs -f` | `bash scripts/logs.sh --follow` |
| Restart server | `docker-compose restart` | `bash scripts/stop.sh && scripts/start.sh` |
| Update mods | `docker-compose run --rm mod-updater` | `bash scripts/update_mods.sh` |
| Backup world | `docker-compose exec... tar` | `bash scripts/backup.sh` |
| Check status | `docker-compose ps` | `bash scripts/status.sh` |
| Add admin | Edit `env/admins.txt` + restart | Edit `env/admins.txt` + restart |

---

## Getting Started

### **I chose Docker:**
→ Go to `DOCKER_GUIDE.md`

### **I chose Native macOS:**
→ Go to `native-macos/README.md` or `QUICKSTART.md`

### **I'm not sure:**
→ Start with **Docker** if you have Docker installed (easier)
→ Start with **Native macOS** if you prefer simplicity (faster)

Both work equally well! Pick one and go!
