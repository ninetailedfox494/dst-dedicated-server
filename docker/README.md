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
| `DST_CLUSTER_KEY` | `defaultPass` | Shared key between shards |

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
docker-compose restart dst        # Restart server and reload env/.env
```

### Safe Reconfigure (No Data Loss)

```bash
# 1) Edit config
nano env/.env

# 2) Recreate container safely (keeps ./data and ./steam)
docker-compose down --remove-orphans

# 3) Rebuild image with latest entrypoint/template
docker-compose build dst

# 4) Start server
docker-compose up -d dst

# 5) Verify generated cluster config
docker-compose exec dst sh -lc 'cat /home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}/cluster.ini'
```

⚠️ Never run `docker-compose down -v` unless you intentionally want to remove Docker volumes.

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

### `ContainerConfig` Error During Recreate

`docker-compose` v1.29.2 can fail with `KeyError: 'ContainerConfig'` when using `--force-recreate`.

```bash
docker-compose down --remove-orphans
docker-compose up -d dst
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
