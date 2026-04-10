# README Runbook Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite README into a cleaner, step-by-step runbook for new users while keeping current project behavior.

**Architecture:** Keep runtime untouched and only update documentation. Use quickstart-first ordering and command-first sections. Retain all currently supported commands/scripts and avoid decorative or long explanatory content.

**Tech Stack:** Markdown, Docker Compose commands, existing repo scripts

---

### Task 1: Add failing tests for required README structure

**Files:**
- Create: `tests/smoke/test_readme_runbook_sections.sh`
- Test: `README.md`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

grep -q "## Quick Run (First Time)" README.md
grep -q "## Daily Commands" README.md
grep -q "## Update Mods" README.md
grep -q "## ENV Reference" README.md
echo "PASS: runbook sections present"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_readme_runbook_sections.sh`  
Expected: FAIL before README rewrite.

- [ ] **Step 3: Write minimal implementation**

```markdown
# DST Dedicated Server with Docker (Master + Caves)

## Quick Run (First Time)
## Daily Commands
## Update Mods
## ENV Reference
## Troubleshooting
## Security
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/smoke/test_readme_runbook_sections.sh`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tests/smoke/test_readme_runbook_sections.sh README.md
git commit -m "test: add runbook section guard for readme"
```

### Task 2: Rewrite README with command-first onboarding flow

**Files:**
- Modify: `README.md`
- Test: `tests/smoke/test_docs_and_env.sh`
- Test: `tests/smoke/test_readme_mod_update_flow.sh`
- Test: `tests/smoke/test_readme_runbook_sections.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

grep -q "docker compose up -d --build" README.md
grep -q "bash scripts/update_mods.sh" README.md
grep -q "docker compose logs -f dst-master" README.md
grep -q "DST_CLUSTER_TOKEN" README.md
echo "PASS: key command flow exists"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_readme_command_flow.sh`  
Expected: FAIL before final rewrite.

- [ ] **Step 3: Write minimal implementation**

```markdown
# DST Dedicated Server with Docker (Master + Caves)

## Quick Run (First Time)
```bash
cp env/.env.example env/.env
docker compose up -d --build
docker compose ps
docker compose logs -f dst-master
docker compose logs -f dst-caves
```

## Daily Commands
```bash
docker compose ps
docker compose restart
docker compose down
docker compose build --no-cache
docker compose up -d
```

## Update Mods
```bash
bash scripts/update_mods.sh
docker compose --profile tools run --rm mod-updater
```

## ENV Reference
| Variable | Example |
|---|---|
| `DST_CLUSTER_TOKEN` | `pds-...` |
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
bash tests/smoke/test_docs_and_env.sh
bash tests/smoke/test_readme_mod_update_flow.sh
bash tests/smoke/test_readme_runbook_sections.sh
bash tests/smoke/test_readme_command_flow.sh
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md tests/smoke/test_readme_command_flow.sh
git commit -m "docs: optimize readme with step-by-step runbook commands"
```

