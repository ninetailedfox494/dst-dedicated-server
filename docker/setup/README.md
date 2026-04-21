# Docker Setup Tools

Quick initialization scripts for Docker environment setup.

## Scripts

### `init_docker_env.sh`

Automated Docker environment initialization.

**What it does:**
- Creates directory structure (`env/`, `data/`, `backups/`, `logs/`)
- Generates `.env` file with documented variables
- Creates `mods.txt` with popular mod examples
- Creates admin/whitelist/blocklist files
- Provides next steps guidance

**Usage:**
```bash
bash init_docker_env.sh
```

**Safe to run:**
- ✅ Multiple times (idempotent)
- ✅ Won't overwrite existing `.env` (if present)
- ✅ Respects existing configurations

**After running:**
1. Edit `env/.env` with your cluster token
2. Run `docker-compose up -d` from parent directory
3. Check `docker-compose logs -f` for startup

## Quick Start

```bash
# From docker/ directory
bash setup/init_docker_env.sh

# Then configure
nano env/.env

# Then run
docker-compose up -d
```

## Documentation

For detailed Docker operations, see:
- `../DOCKER_RUN_GUIDE.md` - Step-by-step guide
- `../DOCKER_GUIDE.md` - Complete reference
- `../README.md` - Overview
