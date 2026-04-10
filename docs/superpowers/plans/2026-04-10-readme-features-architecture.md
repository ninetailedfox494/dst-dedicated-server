# README Features & Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand README with richer Features and Architecture sections while preserving the existing quick command runbook.

**Architecture:** This is a documentation-only change. We add a concrete features table plus architecture tree and runtime flow that reflect the current Docker Compose services and scripts. Existing command sections stay intact so onboarding remains command-first.

**Tech Stack:** Markdown, Docker Compose, Bash scripts

---

### Task 1: Add README guards for new sections

**Files:**
- Create: `tests/smoke/test_readme_features_architecture.sh`
- Test: `README.md`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

grep -q "## Features" README.md
grep -q "## Architecture" README.md
grep -q "dst-master" README.md
grep -q "mod-updater" README.md
echo "PASS: features and architecture sections exist"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_readme_features_architecture.sh`  
Expected: FAIL because the new sections are not yet present.

- [ ] **Step 3: Write minimal implementation**

```markdown
## Features

| Feature | Description |
|---|---|
| Multi-shard | Master + Caves |

## Architecture

Services: dst-master, dst-caves, mod-updater
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/smoke/test_readme_features_architecture.sh`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/smoke/test_readme_features_architecture.sh README.md
git commit -m "test: add readme guards for features and architecture sections"
```

### Task 2: Expand README with detailed Features and Architecture content

**Files:**
- Modify: `README.md`
- Test: `tests/smoke/test_docs_and_env.sh`
- Test: `tests/smoke/test_readme_mod_update_flow.sh`
- Test: `tests/smoke/test_readme_features_architecture.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

grep -q "## Features" README.md
grep -q "## Architecture" README.md
grep -q "## Runtime Services" README.md
grep -q "## Component Flow" README.md
grep -q "docker compose up -d --build" README.md
grep -q "bash scripts/update_mods.sh" README.md
echo "PASS: detailed readme structure and command flow present"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_readme_detailed_structure.sh`  
Expected: FAIL before README is fully expanded.

- [ ] **Step 3: Write minimal implementation**

```markdown
## Features
| Feature | Description |
|---|---|
| Dual Shard | `dst-master` + `dst-caves` |
| Mod Update | `bash scripts/update_mods.sh` |

## Architecture

## Project Structure
```text
docker-compose.yml
Dockerfile
docker/entrypoint.sh
scripts/update_mods.sh
scripts/reset_and_install_mods_docker.sh
env/.env.example
env/mods.txt
```

## Runtime Services
- `dst-master`
- `dst-caves`
- `mod-updater`

## Component Flow
- First run: `env/.env` -> `docker compose up -d --build` -> shards start
- Mod update: `env/mods.txt` -> `bash scripts/update_mods.sh` -> restart shards
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
bash tests/smoke/test_docs_and_env.sh
bash tests/smoke/test_readme_mod_update_flow.sh
bash tests/smoke/test_readme_features_architecture.sh
bash tests/smoke/test_readme_detailed_structure.sh
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md tests/smoke/test_readme_detailed_structure.sh
git commit -m "docs: add detailed features and architecture sections to readme"
```

