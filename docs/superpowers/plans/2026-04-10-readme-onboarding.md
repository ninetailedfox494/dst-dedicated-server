# README Onboarding Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite README so new users can run the DST Docker server with minimal confusion.

**Architecture:** Keep runtime behavior unchanged and only improve documentation flow. Use a quickstart-first structure, then operational commands, mod update flow, env reference, troubleshooting, and security notes. Write each section bilingually (English + Vietnamese) with short, copy/paste-friendly instructions.

**Tech Stack:** Markdown, Docker Compose command examples, existing project scripts

---

### Task 1: Rewrite README structure and beginner flow

**Files:**
- Modify: `README.md`
- Test: `tests/smoke/test_docs_and_env.sh`
- Test: `tests/smoke/test_readme_mod_update_flow.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

grep -q "## Quick Start / Khoi dong nhanh" README.md
grep -q "## Daily Commands / Lenh hang ngay" README.md
grep -q "## Update Mods / Cap nhat mod" README.md
echo "PASS: beginner sections exist"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_readme_beginner_sections.sh`  
Expected: FAIL because section titles do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```markdown
# DST Dedicated Server with Docker (Master + Caves)

Simple guide for first-time setup and daily use.  
Huong dan don gian cho nguoi moi cai dat va van hanh.

## Quick Start / Khoi dong nhanh
1. Copy env:
   ```bash
   cp env/.env.example env/.env
   ```
2. Set token in `env/.env`:
   `DST_CLUSTER_TOKEN=...`
3. Start server:
   ```bash
   docker compose up -d --build
   ```
4. Check status:
   ```bash
   docker compose ps
   ```
5. Watch logs:
   ```bash
   docker compose logs -f dst-master
   docker compose logs -f dst-caves
   ```

## Daily Commands / Lenh hang ngay
```bash
docker compose ps
docker compose restart
docker compose down
```

## Update Mods / Cap nhat mod
```bash
bash scripts/update_mods.sh
```
```

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
bash tests/smoke/test_docs_and_env.sh
bash tests/smoke/test_readme_mod_update_flow.sh
bash tests/smoke/test_readme_beginner_sections.sh
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md tests/smoke/test_readme_beginner_sections.sh
git commit -m "docs: rewrite readme for beginner onboarding flow"
```

### Task 2: Add clear env reference and troubleshooting

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

grep -q "DST_CLUSTER_TOKEN" README.md
grep -q "DST_CLUSTER_NAME" README.md
grep -q "Missing token" README.md
grep -q "Server not discoverable" README.md
echo "PASS: env and troubleshooting guidance present"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_readme_env_troubleshooting.sh`  
Expected: FAIL before adding the new table/wording.

- [ ] **Step 3: Write minimal implementation**

```markdown
## Important Environment Values / Bien moi truong quan trong

| Variable | Meaning | Example |
|---|---|---|
| `DST_CLUSTER_TOKEN` | Klei cluster token | `pds-...` |
| `DST_CLUSTER_NAME` | Cluster folder name | `MyDediServer` |
| `DST_CLUSTER_PASSWORD` | In-game password | `8` |
| `DST_WORLD_SIZE` | World size | `small` |

## Troubleshooting / Xu ly su co
- Missing token: set `DST_CLUSTER_TOKEN` in `env/.env`
- Server not discoverable: open UDP ports 10999/10998/27016/27017/8766/8767
- Mod update failed: verify IDs in `env/mods.txt`, run `bash scripts/update_mods.sh` again
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/smoke/test_readme_env_troubleshooting.sh`  
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md tests/smoke/test_readme_env_troubleshooting.sh
git commit -m "docs: add env reference and troubleshooting for new users"
```

