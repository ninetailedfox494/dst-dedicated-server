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

## Docker-Specific Issues

### Container Won't Start

```bash
docker-compose logs dst-master
cat env/.env | grep DST_CLUSTER_TOKEN
docker-compose up -d --build
```

### Error: "Could not create directories directly"

**Symptom:** Containers exit immediately with repeated warnings:
```
Warning: Could not create directories directly
This may be a volume permissions issue.
Please ensure data/ directory has correct permissions on host.
```

**Cause:** The `data/` directory doesn't exist or has wrong permissions.

**Solution:**
```bash
# 1. Run the init script (creates directories with correct permissions)
./setup/init_docker_env.sh

# 2. Or manually create and set permissions
mkdir -p data/{cluster,master,caves,mods}
chmod -R 777 data/

# 3. Restart
docker-compose down && docker-compose up -d
```

### Error: "libcurl-gnutls.so.4: cannot open shared object file"

**Symptom:** Container starts but crashes with:
```
error while loading shared libraries: libcurl-gnutls.so.4: cannot open shared object file: No such file or directory
```

**Cause:** Missing library in Docker image.

**Solution:** Rebuild the image with updated dependencies:
```bash
docker-compose build --no-cache
docker-compose up -d
```

If issue persists, ensure Dockerfile includes `libcurl4-gnutls-dev:i386`:
```dockerfile
RUN apt-get install -y --no-install-recommends \
    libcurl4:i386 \
    libcurl4-gnutls-dev:i386 \
    ...
```

### Permission Issues (Docker)

**Symptom:** Container starts but logs show "Permission denied" when writing to `data/` folders.

**Why it happens:** Docker container runs as non-root user (UID 1000), but host folders were created by root or different user.

```bash
# Check current ownership
ls -la data/

# Fix: Change ownership to match container user (UID 1000)
sudo chown -R 1000:1000 data/

# Restart
docker-compose down
docker-compose up -d
```

**Alternative (less secure):**
```bash
sudo chmod -R 777 data/
```

**On VPS:** If you created folders as root, this is the most common cause. Always run `chown` after creating data directories.

### Out of Memory (Docker)

Increase Docker memory in Docker Desktop settings, or add limits:
```yaml
# docker-compose.yml
deploy:
  resources:
    limits:
      memory: 2G
```

### Mods Not Loading (Docker)

```bash
docker-compose logs dst-master | grep -i mod
ls data/mods/workshop_*/
docker-compose run --rm mod-updater
docker-compose restart
```

---

For more help, see the platform-specific guides:
- **Docker:** [docker/README.md](docker/README.md)
- **macOS Native:** [native-macos/README.md](native-macos/README.md)
