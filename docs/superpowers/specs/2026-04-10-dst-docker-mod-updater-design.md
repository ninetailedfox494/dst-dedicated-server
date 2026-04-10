# DST Docker Mod Updater Design

## Goal

Convert the VM-style `reset_and_install_mods.sh` behavior into Docker-native operations so users can refresh workshop mods safely for a DST Master+Caves stack.

## Scope

In scope:
- Reset old mod cache and server mod config
- Download latest workshop mods via SteamCMD with `validate`
- Rebuild `dedicated_server_mods_setup.lua` and shard `modoverrides.lua`
- Docker Compose one-shot updater workflow
- README runbook for update/rollback troubleshooting

Out of scope:
- Auto-scheduled updates
- UI dashboard
- Cross-host orchestration

## Chosen Approach

Use a one-shot Compose service `mod-updater` (recommended).

Why:
- Isolated and repeatable update job
- No need to keep update logic in long-running shard entrypoint
- Easier to run manually on demand when players request mod refresh

## Architecture

1. `mod-updater` service in `docker-compose.yml`
- Uses same image as shards
- Reads env from `env/.env`
- Mounts shared cluster and server data folders
- Runs dedicated updater script and exits

2. `scripts/reset_and_install_mods_docker.sh`
- Reads mod IDs from `env/mods.txt` (one ID per line)
- Clears old workshop directories in server and SteamCMD cache
- Regenerates:
  - `dst_server/mods/dedicated_server_mods_setup.lua`
  - `.../Master/modoverrides.lua`
  - `.../Caves/modoverrides.lua`
- Prints success/fail summary by mod ID

3. `scripts/update_mods.sh`
- Stops running shards
- Runs one-shot updater service
- Starts shards back up

## Data and Config

- `env/mods.txt` format:
  - Supports blank lines and `#` comments
  - Every non-comment line is a workshop mod ID
- Secret values remain in `env/.env` (`DST_CLUSTER_TOKEN`, etc.)
- No secrets hardcoded in scripts

## Error Handling

- If `mods.txt` has zero valid IDs, updater exits with clear error
- If workshop dir cannot be found, updater exits non-zero
- Script continues per-mod even if one mod fails, then returns non-zero when all failed
- Summary table includes per-mod status and reason

## Operational Flow

1. Edit `env/mods.txt` with desired mods
2. Run `bash scripts/update_mods.sh`
3. Verify logs/health:
   - `docker compose logs -f dst-master`
   - `docker compose logs -f dst-caves`
4. Validate in-game (mods loaded, caves transition)

## Testing

- Add smoke test for mods.txt parser and config generation output
- Verify updater script fails when required paths are missing
- Verify compose contains `mod-updater` service and command

