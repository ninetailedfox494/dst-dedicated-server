# DST Dedicated Server with Docker (Master + Caves)

Fast command runbook for new users.  
Runbook lenh nhanh cho nguoi moi.

## What this project runs / Du an nay chay gi

- Master + Caves shards
- Docker Compose on 1 VPS
- Config: `env/.env`
- Mod list: `env/mods.txt`

## Requirements / Yeu cau

- Docker Engine
- Docker Compose (`docker compose` preferred)
- Open UDP ports: `10999`, `10998`, `27016`, `27017`, `8766`, `8767`

## OS Compatibility / Tuong thich he dieu hanh

| OS | Support |
|---|---|
| macOS | Supported (Docker Desktop + `docker compose`) |
| Linux | Supported (Docker Engine + Compose plugin) |
| Windows | Supported via WSL or Git Bash (`bash`-based helper scripts are not for native `cmd.exe`) |

> Use a Bash shell for helper commands in `scripts/` (`update_mods.sh`, `set_admin.sh`, `set_access_lists.sh`, `sync_mod_defaults.sh`).

## Features

| Feature | Project Details |
|---|---|
| Dual shard runtime | `dst-master` (surface world) and `dst-caves` (cave shard) run from the same image with shard-specific env. |
| One-command bootstrap | `docker compose up -d --build` builds the image and starts both shards with mounted cluster data. |
| Mod lifecycle workflow | `mod-updater` service + `bash scripts/update_mods.sh` refresh workshop mods from `env/mods.txt`. |
| Persistent data mounts | `./data/cluster`, `./data/master`, `./data/caves`, and `./data/mods` keep worlds/mods across restarts. |
| Config-driven setup | `env/.env` controls token, cluster identity, game mode, world size, and player limits. |

## Architecture

This repository runs a 2-shard DST dedicated server with an optional mod maintenance container. Compose orchestrates service lifecycle, while entrypoint and scripts generate cluster config and mod files from env-driven inputs.

## Project Structure

```text
.
├── Dockerfile
├── docker-compose.yml
├── docker/
│   └── entrypoint.sh
├── env/
│   ├── .env.example
│   └── mods.txt
├── scripts/
│   ├── update_mods.sh
│   └── reset_and_install_mods_docker.sh
└── tests/smoke/
    ├── test_docs_and_env.sh
    ├── test_readme_features_architecture.sh
    └── test_readme_mod_update_flow.sh
```

## Runtime Services

- `dst-master`: primary shard, opens UDP `10999`, `27016`, `8766`, writes cluster and Master configs.
- `dst-caves`: secondary shard, opens UDP `10998`, `27017`, `8767`, shares cluster/mod volumes with Master.
- `mod-updater` (profile: `tools`): runs `scripts/reset_and_install_mods_docker.sh` to reinstall mods listed in `env/mods.txt`.

## Component Flow

1. Operator prepares `env/.env` and `env/mods.txt`.
2. `docker compose up -d --build` builds `dst-dedicated:latest` and starts `dst-master` + `dst-caves`.
3. `docker/entrypoint.sh` validates env, writes cluster/shard files, then launches DST binaries.
4. For mod refresh, `bash scripts/update_mods.sh` stops shards, runs `mod-updater`, then starts shards again.

## Quick Run (First Time) / Chay lan dau

### Step 1: Update token in existing env file / Cap nhat token trong file env co san
```bash
vi env/.env
```
Update `DST_CLUSTER_TOKEN=YOUR_REAL_TOKEN` in `env/.env` (replace `REPLACE_WITH_REAL_TOKEN`).
`DST_CLUSTER_TOKEN` is used to generate `cluster_token.txt` at startup.
You must replace REPLACE_WITH_REAL_TOKEN before first run.

Cap nhat `DST_CLUSTER_TOKEN=YOUR_REAL_TOKEN` trong `env/.env` (thay `REPLACE_WITH_REAL_TOKEN`).
`DST_CLUSTER_TOKEN` duoc dung de tao `cluster_token.txt` khi khoi dong.
Ban phai thay `REPLACE_WITH_REAL_TOKEN` truoc lan chay dau.

### Step 2: Start server / Chay server
```bash
docker compose up -d --build
```

### Step 3: Check status / Kiem tra trang thai
```bash
docker compose ps
```

### Step 4: Check logs / Xem log
```bash
docker compose logs -f dst-master
docker compose logs -f dst-caves
```

## Daily Commands / Lenh hang ngay

```bash
# Start
docker compose up -d

# Status
docker compose ps

# Logs
docker compose logs -f dst-master
docker compose logs -f dst-caves

# Restart
docker compose restart

# Stop
docker compose down
```

## Update Mods / Cap nhat mod

### Step 1: Edit mod list / Sua danh sach mod
```bash
vi env/mods.txt
```

### Step 2: Run updater / Chay updater
```bash
bash scripts/update_mods.sh
```

### Optional: updater only / Chi updater
```bash
 # 1) Update mods (remove old + apply new from env/mods.txt)
docker compose --profile tools run --rm mod-updater
 
 # 2) Apply admin/whitelist/blocklist files
docker compose --profile tools run --rm access-manager
```

## Sync Mod Default Options

```bash
bash scripts/sync_mod_defaults.sh
```

This command reads defaults from downloaded `modinfo.lua` files and rewrites `docker/templates/modoverrides.lua.tmpl`.
It fails if any modinfo.lua is missing.

## Rebuild After DST Update / Build lai khi DST update

```bash
docker compose build --no-cache
docker compose up -d
```

## ENV Reference / Bien ENV quan trong

| Variable | Example | Use |
|---|---|---|
| `DST_CLUSTER_TOKEN` | `pds-...` | Required Klei token |
| `DST_CLUSTER_NAME` | `MyDediServer` | Cluster folder name |
| `DST_CLUSTER_DISPLAY_NAME` | `NineTailedFox` | Server list name |
| `DST_CLUSTER_PASSWORD` | `8` | Join password |
| `DST_GAME_MODE` | `endless` | Game mode |
| `DST_MAX_PLAYERS` | `6` | Player limit |
| `DST_WORLD_SIZE` | `small` | World size |

## Troubleshooting / Xu ly su co

- Missing token: set `DST_CLUSTER_TOKEN` in `env/.env`.
- Server not discoverable: check VPS firewall + UDP ports.
- Mods not loading: check `docker compose logs -f dst-master`.
- Mod update failed: verify IDs in `env/mods.txt`, rerun `bash scripts/update_mods.sh`.
- On Windows, run project commands from WSL/Git Bash (not native `cmd.exe`).

## Security / Bao mat

- Do not commit `env/.env`.
- `env/.env.example` is a public template file.
- `env/.env` must contain your private real `DST_CLUSTER_TOKEN`.
- Keep real token/password only in local env.
- Rotate the token if exposed.
- Integrated Admin, Whitelist, and Blocklist controls.
- Configure IDs in:
  - `env/admins.txt`
  - `env/whitelist.txt`
  - `env/blocklist.txt`
- Apply on host:
  - `bash scripts/set_admin.sh`
  - `bash scripts/set_access_lists.sh`
- Apply via Docker tools profile:
  - `docker compose --profile tools run --rm access-manager`
