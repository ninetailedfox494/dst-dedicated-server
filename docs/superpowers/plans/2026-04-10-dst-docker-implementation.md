# DST Docker Dedicated Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Docker Compose-based DST dedicated server (Master + Caves) converted from the VM script, with env-based secrets and full README operations.

**Architecture:** One reusable DST image powers two Compose services (`dst-master`, `dst-caves`). A shared cluster/config volume keeps token/mod parity, while shard-specific data/log paths avoid collisions. Entrypoint renders runtime config from `.env` and then starts the selected shard.

**Tech Stack:** Docker, Docker Compose, Bash, SteamCMD, DST dedicated server binaries, Markdown docs

---

## File Structure

- `Dockerfile`: DST runtime image with SteamCMD and 32-bit libs.
- `docker/entrypoint.sh`: env validation, config generation, shard startup.
- `docker/templates/*.tmpl`: cluster/shard/mod templates rendered by entrypoint.
- `docker-compose.yml`: two shard services, ports, health checks, volumes.
- `env/.env.example`: all runtime configuration keys with placeholders.
- `.gitignore`: ignore local `.env` and runtime artifacts.
- `README.md`: setup, run, update, status, troubleshooting.
- `tests/smoke/test_entrypoint_env_validation.sh`: red/green test for required env guards.
- `tests/smoke/test_template_render.sh`: red/green test for config rendering.

### Task 1: Scaffold project and first failing test (required env validation)

**Files:**
- Create: `tests/smoke/test_entrypoint_env_validation.sh`
- Create: `docker/entrypoint.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

export DST_CLUSTER_NAME="MyDediServer"
unset DST_CLUSTER_TOKEN || true
export DST_SHARD_NAME="Master"
export DST_INSTALL_DIR="${TMP_DIR}/dst_server"
export DST_CLUSTER_DIR="${TMP_DIR}/cluster"

mkdir -p "${DST_INSTALL_DIR}/bin64"
touch "${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64"
chmod +x "${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64"

set +e
bash docker/entrypoint.sh >"${TMP_DIR}/out.log" 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -eq 0 ]]; then
  echo "Expected failure when DST_CLUSTER_TOKEN missing"
  exit 1
fi

grep -q "DST_CLUSTER_TOKEN is required" "${TMP_DIR}/out.log"
echo "PASS: missing token fails fast"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_entrypoint_env_validation.sh`  
Expected: FAIL because `docker/entrypoint.sh` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

required_vars=(DST_CLUSTER_NAME DST_CLUSTER_TOKEN DST_SHARD_NAME DST_INSTALL_DIR DST_CLUSTER_DIR)
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "ERROR: ${var} is required" >&2
    exit 1
  fi
done

echo "Entrypoint validated env, startup implementation continues in next tasks."
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/smoke/test_entrypoint_env_validation.sh`  
Expected: PASS with `PASS: missing token fails fast`.

- [ ] **Step 5: Commit**

```bash
git add docker/entrypoint.sh tests/smoke/test_entrypoint_env_validation.sh
git commit -m "test: add env validation red-green test and minimal entrypoint"
```

### Task 2: Add Docker image build for DST runtime

**Files:**
- Create: `Dockerfile`
- Modify: `docker/entrypoint.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

docker build -t dst-server:test . >/tmp/dst-build.log 2>&1 || {
  echo "FAIL: docker image build failed"
  cat /tmp/dst-build.log
  exit 1
}
echo "PASS: docker build succeeds"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_docker_build.sh`  
Expected: FAIL because `Dockerfile` does not exist.

- [ ] **Step 3: Write minimal implementation**

```dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl tar lib32gcc-s1 libstdc++6:i386 libcurl4:i386 && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash dst
USER dst
WORKDIR /home/dst

RUN mkdir -p steamcmd && \
    curl -fsSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz -C steamcmd

RUN /home/dst/steamcmd/steamcmd.sh +force_install_dir /home/dst/dst_server +login anonymous +app_update 343050 validate +quit

COPY --chown=dst:dst docker /home/dst/docker
ENTRYPOINT ["/home/dst/docker/entrypoint.sh"]
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/smoke/test_docker_build.sh`  
Expected: PASS with `docker build succeeds`.

- [ ] **Step 5: Commit**

```bash
git add Dockerfile docker/entrypoint.sh tests/smoke/test_docker_build.sh
git commit -m "feat: add docker image for dst dedicated runtime"
```

### Task 3: Implement template rendering for cluster and shard configs

**Files:**
- Create: `docker/templates/cluster.ini.tmpl`
- Create: `docker/templates/master_server.ini.tmpl`
- Create: `docker/templates/caves_server.ini.tmpl`
- Create: `docker/templates/master_worldgenoverride.lua`
- Create: `docker/templates/caves_worldgenoverride.lua`
- Create: `tests/smoke/test_template_render.sh`
- Modify: `docker/entrypoint.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

export DST_CLUSTER_NAME="MyDediServer"
export DST_CLUSTER_TOKEN="pds-example"
export DST_CLUSTER_DISPLAY_NAME="NineTailedFox"
export DST_CLUSTER_DESCRIPTION="Docker DST server"
export DST_CLUSTER_PASSWORD="8"
export DST_GAME_MODE="endless"
export DST_MAX_PLAYERS="6"
export DST_WORLD_SIZE="small"
export DST_SHARD_NAME="Master"
export DST_INSTALL_DIR="${TMP_DIR}/dst_server"
export DST_CLUSTER_DIR="${TMP_DIR}/cluster"

mkdir -p "${DST_INSTALL_DIR}/bin64"
cat > "${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64" <<'EOF'
#!/usr/bin/env bash
echo "fake dst binary"
EOF
chmod +x "${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64"

set +e
bash docker/entrypoint.sh >/dev/null 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -ne 0 ]]; then
  echo "entrypoint should render configs successfully in dry test"
  exit 1
fi

grep -q "cluster_name = NineTailedFox" "${DST_CLUSTER_DIR}/cluster.ini"
grep -q "world_size = \"small\"" "${DST_CLUSTER_DIR}/Master/worldgenoverride.lua"
echo "PASS: templates rendered"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_template_render.sh`  
Expected: FAIL because template rendering is not implemented yet.

- [ ] **Step 3: Write minimal implementation**

```bash
# In docker/entrypoint.sh add:
# - create ${DST_CLUSTER_DIR}/{Master,Caves}
# - write cluster_token.txt from DST_CLUSTER_TOKEN
# - render cluster.ini from env vars
# - choose shard server.ini based on DST_SHARD_NAME
# - write worldgenoverride.lua with DST_WORLD_SIZE
# - exec dst binary with -cluster "${DST_CLUSTER_NAME}" -shard "${DST_SHARD_NAME}"
```

```ini
# docker/templates/cluster.ini.tmpl
[GAMEPLAY]
game_mode = ${DST_GAME_MODE}
max_players = ${DST_MAX_PLAYERS}
pvp = false
pause_when_empty = true

[NETWORK]
cluster_name = ${DST_CLUSTER_DISPLAY_NAME}
cluster_description = ${DST_CLUSTER_DESCRIPTION}
cluster_password = ${DST_CLUSTER_PASSWORD}
cluster_intention = cooperative
lan_only_cluster = false
offline_cluster = false
tick_rate = 15

[SHARD]
shard_enabled = true
bind_ip = 127.0.0.1
master_ip = 127.0.0.1
master_port = 10888
cluster_key = defaultPass
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/smoke/test_template_render.sh`  
Expected: PASS with `templates rendered`.

- [ ] **Step 5: Commit**

```bash
git add docker/entrypoint.sh docker/templates tests/smoke/test_template_render.sh
git commit -m "feat: render cluster and shard config from environment"
```

### Task 4: Add mod parity from VM script

**Files:**
- Create: `docker/templates/modoverrides.lua.tmpl`
- Modify: `docker/entrypoint.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
TARGET_FILE="${DST_CLUSTER_DIR}/Master/modoverrides.lua"
grep -q 'workshop-2078243581' "${TARGET_FILE}"
grep -q 'workshop-1412085556' "${TARGET_FILE}"
echo "PASS: modoverrides contains expected workshop ids"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_mods_render.sh`  
Expected: FAIL because `modoverrides.lua` is not generated yet.

- [ ] **Step 3: Write minimal implementation**

```lua
-- docker/templates/modoverrides.lua.tmpl
return {
  ["workshop-2078243581"] = { enabled = true, configuration_options = {} },
  ["workshop-2798599672"] = { enabled = true, configuration_options = {} },
  ["workshop-374550642"] = { enabled = true, configuration_options = {} },
  ["workshop-1207269058"] = { enabled = true, configuration_options = {} },
  ["workshop-1852257480"] = { enabled = true, configuration_options = {} },
  ["workshop-376333686"] = { enabled = true, configuration_options = {} },
  ["workshop-378160973"] = { enabled = true, configuration_options = {} },
  ["workshop-351325790"] = { enabled = true, configuration_options = {} },
  ["workshop-1608191708"] = { enabled = true, configuration_options = {} },
  ["workshop-345692228"] = { enabled = true, configuration_options = {} },
  ["workshop-362175979"] = { enabled = true, configuration_options = {} },
  ["workshop-347079953"] = { enabled = true, configuration_options = {} },
  ["workshop-597417408"] = { enabled = true, configuration_options = {} },
  ["workshop-569043634"] = { enabled = true, configuration_options = {} },
  ["workshop-1412085556"] = { enabled = true, configuration_options = {} },
}
```

```bash
# In docker/entrypoint.sh also write:
# - ${DST_CLUSTER_DIR}/Master/modoverrides.lua
# - ${DST_CLUSTER_DIR}/Caves/modoverrides.lua
# - ${DST_INSTALL_DIR}/mods/dedicated_server_mods_setup.lua with ServerModSetup(...) for same IDs
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/smoke/test_mods_render.sh`  
Expected: PASS with expected workshop IDs found.

- [ ] **Step 5: Commit**

```bash
git add docker/entrypoint.sh docker/templates/modoverrides.lua.tmpl tests/smoke/test_mods_render.sh
git commit -m "feat: add vm-parity dst workshop mods setup"
```

### Task 5: Compose services, ports, health checks, and status commands

**Files:**
- Create: `docker-compose.yml`
- Modify: `README.md`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
docker compose config >/tmp/dst-compose-config.log
grep -q "dst-master" /tmp/dst-compose-config.log
grep -q "dst-caves" /tmp/dst-compose-config.log
echo "PASS: compose defines both shard services"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_compose_config.sh`  
Expected: FAIL because `docker-compose.yml` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

```yaml
services:
  dst-master:
    build: .
    env_file: [./env/.env]
    environment:
      DST_SHARD_NAME: Master
    ports:
      - "10999:10999/udp"
      - "27016:27016/udp"
      - "8766:8766/udp"
    volumes:
      - ./data/cluster:/home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}
      - ./data/master:/home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}/Master
    restart: unless-stopped

  dst-caves:
    build: .
    env_file: [./env/.env]
    environment:
      DST_SHARD_NAME: Caves
    ports:
      - "10998:10998/udp"
      - "27017:27017/udp"
      - "8767:8767/udp"
    volumes:
      - ./data/cluster:/home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}
      - ./data/caves:/home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}/Caves
    restart: unless-stopped
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/smoke/test_compose_config.sh`  
Expected: PASS with both services detected.

- [ ] **Step 5: Commit**

```bash
git add docker-compose.yml tests/smoke/test_compose_config.sh README.md
git commit -m "feat: add compose topology for master and caves shards"
```

### Task 6: Documentation, env examples, and ignore rules

**Files:**
- Create: `README.md`
- Create: `env/.env.example`
- Create: `.gitignore`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
grep -q "docker compose up -d" README.md
grep -q "DST_CLUSTER_TOKEN=" env/.env.example
grep -q "^env/.env$" .gitignore
echo "PASS: docs and secret-handling files present"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_docs_and_env.sh`  
Expected: FAIL because docs/env files do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```dotenv
# env/.env.example
DST_CLUSTER_NAME=MyDediServer
DST_CLUSTER_DISPLAY_NAME=NineTailedFox
DST_CLUSTER_DESCRIPTION=DST Dedicated Server via Docker
DST_CLUSTER_TOKEN=REPLACE_WITH_REAL_TOKEN
DST_CLUSTER_PASSWORD=8
DST_GAME_MODE=endless
DST_MAX_PLAYERS=6
DST_WORLD_SIZE=small
```

```gitignore
env/.env
data/
```

```markdown
# README
## Quick Start
1. `cp env/.env.example env/.env`
2. Set real `DST_CLUSTER_TOKEN` in `env/.env`
3. `docker compose up -d --build`
4. `docker compose logs -f dst-master`
5. `docker compose logs -f dst-caves`
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/smoke/test_docs_and_env.sh`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md env/.env.example .gitignore tests/smoke/test_docs_and_env.sh
git commit -m "docs: add docker dst setup and env security guidance"
```

### Task 7: Final integration validation

**Files:**
- Modify: `README.md` (validation section)

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail
docker compose config >/dev/null
echo "PASS: compose file validates"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_integration_compose.sh`  
Expected: FAIL if compose has unresolved variable/format issues.

- [ ] **Step 3: Write minimal implementation**

```markdown
## Validation Checklist
- `docker compose config` succeeds
- `docker compose ps` shows `dst-master` and `dst-caves` running
- Logs show shard startup and no missing token error
- In-game: join succeeds and caves transition works
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/smoke/test_integration_compose.sh`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md tests/smoke/test_integration_compose.sh
git commit -m "chore: document and verify docker dst integration checks"
```
