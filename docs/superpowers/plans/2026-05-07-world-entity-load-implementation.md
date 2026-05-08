# World Entity Load Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an opt-in, config-driven world-load optimization that generates `leveldataoverride.lua` for both Master and Caves to reduce CPU-heavy entity simulation.

**Architecture:** Add environment-controlled generation in `docker/entrypoint.sh` using a new template file under `docker/env/`. Keep defaults behavior-safe (`DST_OPTIMIZE_WORLD_LOAD=false`) and expose settings in bootstrap and docs so users can apply changes on new builds or existing servers via rebuild/restart.

**Tech Stack:** Bash, envsubst, Docker Compose, DST Lua config (`leveldataoverride.lua`)

---

## File Structure

- `docker/env/leveldataoverride-balanced.lua.tpl` (create): Template for balanced entity/ocean simulation reductions.
- `docker/entrypoint.sh` (modify): Read new env vars and render template to Master/Caves `leveldataoverride.lua`.
- `docker/setup/init_docker_env.sh` (modify): Seed new env vars in generated `env/.env`.
- `docker/README.md` (modify): Document toggle/profile and safe reconfigure workflow.

### Task 1: Add world-load config template and env defaults

**Files:**
- Create: `docker/env/leveldataoverride-balanced.lua.tpl`
- Modify: `docker/setup/init_docker_env.sh`
- Test: N/A (validated by startup generation in Task 3)

- [ ] **Step 1: Add balanced template file**

```lua
return {
  overrides = {
    hounds = "less",
    frogs = "less",
    bees = "less",
    tumbleweed = "less",
    oceanfish_shoal = "less",
    driftwood = "less",
  }
}
```

- [ ] **Step 2: Add new env vars to Docker bootstrap `.env` creation**

```bash
# ========== WORLD LOAD OPTIMIZATION ==========
# Enable config-driven leveldataoverride.lua generation for both shards
DST_OPTIMIZE_WORLD_LOAD=false

# Available: balanced
DST_WORLD_LOAD_PROFILE=balanced
```

- [ ] **Step 3: Commit Task 1**

```bash
git add docker/env/leveldataoverride-balanced.lua.tpl docker/setup/init_docker_env.sh
git commit -m "feat: add world load optimization template and env defaults"
```

### Task 2: Generate leveldataoverride.lua for Master and Caves

**Files:**
- Modify: `docker/entrypoint.sh`
- Test: Manual runtime verification command in Task 3

- [ ] **Step 1: Add env defaults in entrypoint**

```bash
export DST_OPTIMIZE_WORLD_LOAD="${DST_OPTIMIZE_WORLD_LOAD:-false}"
export DST_WORLD_LOAD_PROFILE="${DST_WORLD_LOAD_PROFILE:-balanced}"
```

- [ ] **Step 2: Add generation logic guarded by toggle**

```bash
if [[ "${DST_OPTIMIZE_WORLD_LOAD}" == "true" ]]; then
  case "${DST_WORLD_LOAD_PROFILE}" in
    balanced)
      LEVELDATA_TEMPLATE="/home/dst/docker/env/leveldataoverride-balanced.lua.tpl"
      ;;
    *)
      echo "ERROR: Unsupported DST_WORLD_LOAD_PROFILE='${DST_WORLD_LOAD_PROFILE}'" >&2
      exit 1
      ;;
  esac

  if [[ ! -f "${LEVELDATA_TEMPLATE}" ]]; then
    echo "ERROR: leveldataoverride template not found: ${LEVELDATA_TEMPLATE}" >&2
    exit 1
  fi

  envsubst < "${LEVELDATA_TEMPLATE}" > "${MASTER_DIR}/leveldataoverride.lua"
  cp "${MASTER_DIR}/leveldataoverride.lua" "${CAVES_DIR}/leveldataoverride.lua"
fi
```

- [ ] **Step 3: Commit Task 2**

```bash
git add docker/entrypoint.sh
git commit -m "feat: generate shard leveldataoverride from env profile"
```

### Task 3: Document usage and verify behavior

**Files:**
- Modify: `docker/README.md`
- Test: Runtime verification commands

- [ ] **Step 1: Add docs for world-load optimization settings**

```markdown
| `DST_OPTIMIZE_WORLD_LOAD` | `false` | `true` enables generated `leveldataoverride.lua` |
| `DST_WORLD_LOAD_PROFILE` | `balanced` | currently `balanced` |
```

- [ ] **Step 2: Add safe reconfigure instructions**

```bash
# 1) Edit env/.env
DST_OPTIMIZE_WORLD_LOAD=true
DST_WORLD_LOAD_PROFILE=balanced

# 2) Recreate safely and start
docker-compose down --remove-orphans
docker-compose build dst
docker-compose up -d dst
```

- [ ] **Step 3: Add verification command examples**

```bash
docker-compose exec dst sh -lc 'cat /home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}/Master/leveldataoverride.lua'
docker-compose exec dst sh -lc 'cat /home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}/Caves/leveldataoverride.lua'
```

- [ ] **Step 4: Commit Task 3**

```bash
git add docker/README.md
git commit -m "docs: add world load optimization usage and verification"
```

### Task 4: Final integration verification

**Files:**
- Modify: none
- Test: End-to-end behavior checks

- [ ] **Step 1: Verify disabled path preserves current behavior**

```bash
docker-compose down --remove-orphans
docker-compose up -d dst
```

Expected: container starts successfully without requiring world-load template generation.

- [ ] **Step 2: Verify enabled path generates both shard files**

```bash
docker-compose down --remove-orphans
docker-compose build dst
docker-compose up -d dst
docker-compose exec dst sh -lc 'test -f /home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}/Master/leveldataoverride.lua && echo MASTER_OK'
docker-compose exec dst sh -lc 'test -f /home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}/Caves/leveldataoverride.lua && echo CAVES_OK'
```

Expected: `MASTER_OK` and `CAVES_OK`.

- [ ] **Step 3: Verify content contains intended reductions**

```bash
docker-compose exec dst sh -lc 'grep -E "hounds|frogs|bees|tumbleweed|oceanfish_shoal|driftwood" /home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}/Master/leveldataoverride.lua'
```

Expected: all target overrides present with `"less"` values.

- [ ] **Step 4: Commit final integrated changes**

```bash
git add docker/env/leveldataoverride-balanced.lua.tpl docker/setup/init_docker_env.sh docker/entrypoint.sh docker/README.md
git commit -m "feat: add config-driven world entity load optimization"
```
