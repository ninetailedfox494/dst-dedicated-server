# Mod Default Config Sync Design

## Goal

Generate explicit default `configuration_options` for all mods listed in `env/mods.txt`, then write them into `docker/templates/modoverrides.lua.tmpl`.

## Scope

In scope:
- Read mod IDs from `env/mods.txt`
- Parse each downloaded `modinfo.lua` for config defaults
- Build explicit `configuration_options` per mod
- Overwrite only `docker/templates/modoverrides.lua.tmpl`
- Fail if any required mod metadata is missing

Out of scope:
- Runtime shard behavior changes
- Automatic regeneration on every update
- Editing runtime `data/cluster/*/modoverrides.lua` files

## Chosen Approach

Use a one-time sync script: `scripts/sync_mod_defaults.sh`.

Why:
- Keeps current workflow stable
- Produces explicit, reviewable template output
- Avoids extra runtime complexity

## Data Sources

1. `env/mods.txt` as source of truth for mod IDs and order
2. `data/mods/workshop-<id>/modinfo.lua` for each mod’s `configuration_options`

If any `modinfo.lua` is missing/unreadable, script exits non-zero.

## Output

Target file:
- `docker/templates/modoverrides.lua.tmpl`

Output format:
- `enabled = true`
- `configuration_options = { ... }` with explicit default key/value entries (no `{}` fallback)

Write mode:
- Generate temporary file first
- Replace target atomically after successful generation

## Value Serialization Rules

- Lua boolean stays `true`/`false`
- Lua numbers stay numeric
- Lua strings are quoted and escaped
- Lua tables are rendered recursively
- Unknown/unsupported values cause explicit failure

## Verification

- Add smoke test that:
  - fails if any mod in `env/mods.txt` has no local `modinfo.lua`
  - fails if template generation exits with error
  - confirms each listed mod appears in the template
  - confirms generated `configuration_options` is explicit (not empty for mods with defaults)

## Operational Flow

1. Ensure mods are downloaded (`bash scripts/update_mods.sh`)
2. Run defaults sync (`bash scripts/sync_mod_defaults.sh`)
3. Review template diff (`docker/templates/modoverrides.lua.tmpl`)
4. Restart/update as needed
