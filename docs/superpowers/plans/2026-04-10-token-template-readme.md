# Token Template Reminder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clarify public template vs private runtime token usage for `DST_CLUSTER_TOKEN` and remind users to update token before first run.

**Architecture:** This is a docs-only change. We update `env/.env.example` with explicit comments and add bilingual reminders in README Quick Run and Security sections. A small smoke test guards presence of the new token guidance text.

**Tech Stack:** Markdown, dotenv comments, bash smoke tests

---

### Task 1: Add failing docs smoke test for token guidance

**Files:**
- Create: `tests/smoke/test_readme_token_reminder.sh`
- Test: `README.md`
- Test: `env/.env.example`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

grep -q "DST_CLUSTER_TOKEN is used to generate cluster_token.txt" README.md
grep -q "must replace REPLACE_WITH_REAL_TOKEN before first run" README.md
grep -q "public template file" env/.env.example
echo "PASS: token reminder docs present"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_readme_token_reminder.sh`  
Expected: FAIL before docs update.

- [ ] **Step 3: Commit failing test**

```bash
git add tests/smoke/test_readme_token_reminder.sh
git commit -m "test: add failing smoke test for token reminder docs"
```

### Task 2: Update `.env.example` and README token reminders

**Files:**
- Modify: `env/.env.example`
- Modify: `README.md`
- Test: `tests/smoke/test_readme_token_reminder.sh`
- Test: `tests/smoke/test_docs_and_env.sh`

- [ ] **Step 1: Update `env/.env.example` comments**

```dotenv
# Public template file (safe to commit).
# Copy to env/.env and set private real values before running.
# IMPORTANT: replace DST_CLUSTER_TOKEN with your real Klei token.
DST_CLUSTER_NAME=MyDediServer
DST_CLUSTER_DISPLAY_NAME=NineTailedFox
DST_CLUSTER_DESCRIPTION=DST Dedicated Server via Docker
DST_CLUSTER_TOKEN=REPLACE_WITH_REAL_TOKEN
DST_CLUSTER_PASSWORD=8
DST_GAME_MODE=endless
DST_MAX_PLAYERS=6
DST_WORLD_SIZE=small
```

- [ ] **Step 2: Update README Quick Run token note**

```markdown
### Step 2: Set token / Gan token
```bash
sed -i.bak 's/^DST_CLUSTER_TOKEN=.*/DST_CLUSTER_TOKEN=REPLACE_WITH_REAL_TOKEN/' env/.env
```
`DST_CLUSTER_TOKEN` is used to generate `cluster_token.txt` at startup.  
`DST_CLUSTER_TOKEN` duoc dung de tao `cluster_token.txt` khi khoi dong.
You must replace `REPLACE_WITH_REAL_TOKEN` before first run.  
Ban phai thay `REPLACE_WITH_REAL_TOKEN` truoc lan chay dau.
```

- [ ] **Step 3: Update README Security reminder**

```markdown
- `.env.example` is a public template file.
- `env/.env` must contain your private real `DST_CLUSTER_TOKEN`.
- Rotate the token if exposed.
```

- [ ] **Step 4: Run docs tests**

Run:
```bash
bash tests/smoke/test_readme_token_reminder.sh
bash tests/smoke/test_docs_and_env.sh
```
Expected: PASS.

- [ ] **Step 5: Commit docs updates**

```bash
git add env/.env.example README.md tests/smoke/test_readme_token_reminder.sh
git commit -m "docs: add public template and token update reminders"
```
