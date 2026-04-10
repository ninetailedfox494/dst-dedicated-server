# Init Env Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one command that creates/updates `env/.env` and sets `DST_CLUSTER_TOKEN` from user input.

**Architecture:** Add a small interactive script (`scripts/init_env.sh`) that copies `env/.env.example` when needed and updates only the token key. Update README quick-start to use the script instead of manual editor steps. Keep all behavior docs-only plus helper script; no runtime server logic changes.

**Tech Stack:** Bash, Markdown, existing smoke tests

---

### Task 1: Add failing smoke test for init-env flow

**Files:**
- Create: `tests/smoke/test_init_env_script.sh`
- Test: `scripts/init_env.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/env"
cat > "${TMP_DIR}/env/.env.example" <<'EOF'
DST_CLUSTER_TOKEN=REPLACE_WITH_REAL_TOKEN
DST_CLUSTER_NAME=MyDediServer
EOF

set +e
printf "pds-real-token\n" | \
ENV_EXAMPLE_FILE="${TMP_DIR}/env/.env.example" \
ENV_FILE="${TMP_DIR}/env/.env" \
bash scripts/init_env.sh > "${TMP_DIR}/out.log" 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -ne 0 ]]; then
  cat "${TMP_DIR}/out.log"
  echo "Expected init_env.sh to succeed"
  exit 1
fi

grep -q '^DST_CLUSTER_TOKEN=pds-real-token$' "${TMP_DIR}/env/.env"
echo "PASS: init_env.sh writes token into env file"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_init_env_script.sh`  
Expected: FAIL because `scripts/init_env.sh` does not exist yet.

- [ ] **Step 3: Commit failing test**

```bash
git add tests/smoke/test_init_env_script.sh
git commit -m "test: add failing smoke test for init env script"
```

### Task 2: Implement init-env script

**Files:**
- Create: `scripts/init_env.sh`
- Test: `tests/smoke/test_init_env_script.sh`

- [ ] **Step 1: Write minimal implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

ENV_EXAMPLE_FILE="${ENV_EXAMPLE_FILE:-env/.env.example}"
ENV_FILE="${ENV_FILE:-env/.env}"

[[ -f "${ENV_EXAMPLE_FILE}" ]] || { echo "ERROR: missing ${ENV_EXAMPLE_FILE}" >&2; exit 1; }

mkdir -p "$(dirname "${ENV_FILE}")"
[[ -f "${ENV_FILE}" ]] || cp "${ENV_EXAMPLE_FILE}" "${ENV_FILE}"

echo -n "Enter DST_CLUSTER_TOKEN: "
read -r TOKEN
[[ -n "${TOKEN}" ]] || { echo "ERROR: token cannot be empty" >&2; exit 1; }

if grep -q '^DST_CLUSTER_TOKEN=' "${ENV_FILE}"; then
  sed -i.bak "s/^DST_CLUSTER_TOKEN=.*/DST_CLUSTER_TOKEN=${TOKEN}/" "${ENV_FILE}"
  rm -f "${ENV_FILE}.bak"
else
  printf '\nDST_CLUSTER_TOKEN=%s\n' "${TOKEN}" >> "${ENV_FILE}"
fi

echo "env updated: ${ENV_FILE}"
echo "Next: docker compose up -d --build"
```

- [ ] **Step 2: Make script executable**

Run: `chmod +x scripts/init_env.sh tests/smoke/test_init_env_script.sh`

- [ ] **Step 3: Run test to verify it passes**

Run: `bash tests/smoke/test_init_env_script.sh`  
Expected: PASS with `PASS: init_env.sh writes token into env file`.

- [ ] **Step 4: Commit script**

```bash
git add scripts/init_env.sh tests/smoke/test_init_env_script.sh
git commit -m "feat: add init env script for token setup"
```

### Task 3: Update README quick-start and token reminder

**Files:**
- Modify: `README.md`
- Test: `tests/smoke/test_readme_token_reminder.sh`
- Test: `tests/smoke/test_docs_and_env.sh`

- [ ] **Step 1: Update Quick Run steps**

```markdown
### Step 1: Init env + token / Tao env + nhap token
```bash
bash scripts/init_env.sh
```

### Step 2: Start server / Chay server
```bash
docker compose up -d --build
```
```

- [ ] **Step 2: Keep token reminder text**

```markdown
`DST_CLUSTER_TOKEN` is used to generate `cluster_token.txt` at startup.
You must replace REPLACE_WITH_REAL_TOKEN before first run.
```

- [ ] **Step 3: Run docs tests**

Run:
```bash
bash tests/smoke/test_readme_token_reminder.sh
bash tests/smoke/test_docs_and_env.sh
```
Expected: PASS.

- [ ] **Step 4: Commit README update**

```bash
git add README.md
git commit -m "docs: simplify quick start with init env script"
```
