# Admin Access Controls Design

## Goal

Add admin/access-list management to the Docker DST project, based on the provided VM script behavior, while keeping current runbook workflow.

## Scope

In scope:
- Add admin IDs source file
- Add scripts to generate `adminlist.txt`, `whitelist.txt`, `blocklist.txt`
- Add optional Docker one-shot service for access-list management
- Update README security section with integrated controls

Out of scope:
- Runtime shard behavior changes
- Automatic syncing with external user database

## Chosen Approach

Use both:
1. Host script workflow (fast local execution)
2. Optional one-shot Docker service (containerized execution)

This gives flexibility for different operator preferences.

## Files to Add/Update

- Add: `env/admins.txt`
- Add: `env/whitelist.txt` (optional entries, comment-ready)
- Add: `env/blocklist.txt` (optional entries, comment-ready)
- Add: `scripts/set_admin.sh`
- Add: `scripts/set_access_lists.sh`
- Update: `docker-compose.yml` (new optional service `access-manager`)
- Update: `README.md` (security + commands)

## Data/Path Model

- Source files:
  - `env/admins.txt`
  - `env/whitelist.txt`
  - `env/blocklist.txt`
- Target files in mounted cluster data:
  - `data/cluster/adminlist.txt`
  - `data/cluster/whitelist.txt`
  - `data/cluster/blocklist.txt`

Scripts will:
- Ignore blank lines and `#` comments
- Normalize output to one KU ID per line
- Overwrite target files atomically

## Commands

- Host method:
  - `bash scripts/set_admin.sh`
  - `bash scripts/set_access_lists.sh`
- Docker method:
  - `docker compose --profile tools run --rm access-manager`

## Error Handling

- Fail if required source file (`env/admins.txt`) is missing
- Create optional list files if missing (`whitelist`, `blocklist`)
- Fail with clear message if target directory cannot be written

## README Changes

- Add security note: **Integrated Admin, Whitelist, and Blocklist controls**
- Add step-by-step command blocks for both host and Docker methods
- Keep existing quick-start/runbook sections unchanged

## Acceptance Criteria

- Running `bash scripts/set_admin.sh` writes `data/cluster/adminlist.txt`
- Running `bash scripts/set_access_lists.sh` writes all 3 list files
- Docker `access-manager` path works via compose profile `tools`
- README documents integrated controls and exact commands
