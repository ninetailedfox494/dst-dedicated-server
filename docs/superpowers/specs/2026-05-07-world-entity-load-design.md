# World Entity Load Optimization Design

## Problem
Medium DST worlds become CPU-heavy over long-running days due to cumulative entity simulation load, especially ocean systems.  
The project needs a config-driven way to generate `leveldataoverride.lua` for:

- `~/.klei/DoNotStarveTogether/<Cluster>/Master/leveldataoverride.lua`
- `~/.klei/DoNotStarveTogether/<Cluster>/Caves/leveldataoverride.lua`

without manually editing files inside containers.

## Goals

1. Reduce world entity load for: hounds, frogs, bees, tumbleweeds, ocean fish, driftwood.
2. Apply to both Master and Caves.
3. Keep behavior opt-in via config toggle.
4. Support both new server builds and existing server reconfiguration.

## Chosen Approach
Use **env-driven template generation in `docker/entrypoint.sh`**.

### Why
- Matches existing project pattern (env template + startup generation).
- No manual container edits.
- Safe rollout with default-disabled toggle.

## Configuration Design

Add new environment variables:

- `DST_OPTIMIZE_WORLD_LOAD` (`false` by default)
- `DST_WORLD_LOAD_PROFILE` (`balanced` by default)

`balanced` profile applies conservative reductions to targeted entity systems and ocean simulation pressure.

## File/Component Changes

1. Add a `leveldataoverride.lua` template under `docker/env/`.
2. Extend `docker/entrypoint.sh`:
   - read optimization env vars,
   - when enabled, render template and write to both Master and Caves shard folders.
3. Extend environment bootstrap in `docker/setup/init_docker_env.sh` to include new vars in generated `env/.env`.
4. Update `docker/README.md` with:
   - new env options,
   - reconfigure steps for existing servers,
   - verification command for generated override file.

## Data Flow

1. User sets env vars in `docker/env/.env`.
2. Container starts; entrypoint loads runtime env.
3. If optimization enabled:
   - template variables are substituted,
   - output written to both shard override paths.
4. Server starts with adjusted world simulation settings.

## Error Handling

- If optimization is enabled but template missing: fail startup with clear error.
- If optimization disabled: skip generation and preserve existing behavior.

## Testing/Validation Scope

1. Ensure container start still works when optimization is disabled.
2. Ensure generated override file exists in both Master and Caves when enabled.
3. Ensure docs reflect safe reconfigure workflow.

## Out of Scope

- Dynamic profile switching at runtime.
- Fine-grained per-entity env variables beyond the balanced profile.
- Non-Docker path changes in this step.
