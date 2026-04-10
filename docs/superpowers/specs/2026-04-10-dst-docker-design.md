# DST Dedicated Server Docker Design

**Goal:** Convert the existing VM Bash setup into a Docker-based, single-VPS DST dedicated server stack with Master + Caves shards, mod auto-download, environment-based secrets, and clear operational docs.

## Scope

In scope:
- Dockerized DST dedicated server runtime
- Docker Compose deployment on one VPS
- Master + Caves shard topology
- Config generation from `.env` values (including token/password)
- Mods setup parity with VM script
- Operational documentation (run/update/status/troubleshooting)

Out of scope:
- Multi-host orchestration (Swarm/Kubernetes)
- Auto TLS/proxy layer
- External DB/metrics stack

## Architecture

Use one reusable Docker image and two Compose services:
- `dst-master`: starts shard `Master`
- `dst-caves`: starts shard `Caves`

Both services share the same cluster config/mod volume so they use identical cluster identity, token, and mod setup.  
Each service keeps separate shard save/log directories to avoid collisions.

## Components

1. `Dockerfile`
- Base Linux image with 32-bit runtime libs required by DST
- Installs SteamCMD
- Installs DST server binaries to `/opt/dst/server`
- Copies entrypoint + config templates

2. `docker-compose.yml`
- Defines `dst-master` and `dst-caves`
- Shared cluster/config volume mount
- Required UDP port mappings for game/query/auth
- Restart policy for resilience
- Healthchecks for process liveness

3. `docker/entrypoint.sh`
- Reads env vars
- Renders `cluster.ini`, shard `server.ini`, worldgen files, `modoverrides.lua`, and `dedicated_server_mods_setup.lua`
- Ensures `cluster_token.txt` exists from env
- Starts the correct shard process

4. `env/.env.example`
- Contains all configurable values with safe placeholders
- User copies to `.env` and fills secrets

5. `README.md`
- Setup, first boot, update flow, status/log checks, and troubleshooting
- Explicit warning to rotate token and avoid committing real secrets

## Data and Config Flow

1. User copies `.env.example` to `.env` and sets values.
2. `docker compose up -d` launches both services.
3. Each container entrypoint renders runtime files from env and templates.
4. DST binary starts shard with cluster folder mounted from shared volume.
5. On first run, server downloads configured mods and caches them in mounted data.

## Security and Secrets

- Never hardcode `cluster_token` or game password in committed files.
- Keep real token/password only in local `.env`.
- Provide `.gitignore` rule for `.env`.
- README includes secret rotation guidance.

## Error Handling

- Entrypoint should fail fast when required env values are missing (token, cluster name, shard role).
- Healthcheck marks unhealthy when shard process is not running.
- Startup logs should clearly show generated shard role and cluster path.

## Testing and Validation Plan

1. Static validation:
- `docker compose config` renders valid config.

2. Runtime validation:
- Both services become healthy.
- UDP ports are bound as expected.
- Logs show Master then Caves startup and shard handshake.

3. Functional validation:
- Game client can discover/join server.
- Caves transition works.
- Mods from list are downloaded and enabled.

## File Plan

- Create: `Dockerfile`
- Create: `docker-compose.yml`
- Create: `docker/entrypoint.sh`
- Create: `docker/templates/cluster.ini.tmpl`
- Create: `docker/templates/master_server.ini.tmpl`
- Create: `docker/templates/caves_server.ini.tmpl`
- Create: `docker/templates/master_worldgenoverride.lua`
- Create: `docker/templates/caves_worldgenoverride.lua`
- Create: `docker/templates/modoverrides.lua.tmpl`
- Create: `env/.env.example`
- Create: `.gitignore`
- Create: `README.md`

## Trade-off Summary

Chosen approach: **two shard containers with one shared cluster volume**.

Why this approach:
- Better isolation than one-process container design
- Still simple enough for one VPS operations
- Keeps parity with existing Master/Caves split in VM script
- Avoids operational overhead of separate init/update service graph
