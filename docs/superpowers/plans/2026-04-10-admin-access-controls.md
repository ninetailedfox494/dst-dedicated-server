# Admin Access Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add admin/whitelist/blocklist management scripts and document integrated access controls in README.

**Architecture:** Keep the existing Docker runtime unchanged and add lightweight file-driven access control management. Operators manage IDs in `env/*.txt`; scripts write normalized outputs to `data/cluster/*.txt`. An optional `access-manager` one-shot Compose service runs the same script in container context.

**Tech Stack:** Bash, Docker Compose, Markdown, smoke tests

---

### Task 1: Add failing tests for admin/access list generation

**Files:**
- Create: `tests/smoke/test_set_admin_script.sh`
- Create: `tests/smoke/test_set_access_lists_script.sh`

- [ ] **Step 1: Write the failing admin test**

```bash
#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/env" "${TMP_DIR}/data/cluster"
cat > "${TMP_DIR}/env/admins.txt" <<'EOF'
# admins
KU_J9MSQD54
KU_0PX1vpn8
EOF

set +e
ADMINS_FILE="${TMP_DIR}/env/admins.txt" \
CLUSTER_DATA_DIR="${TMP_DIR}/data/cluster" \
bash scripts/set_admin.sh > "${TMP_DIR}/out.log" 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -ne 0 ]]; then
  cat "${TMP_DIR}/out.log"
  echo "Expected set_admin.sh to succeed"
  exit 1
fi

grep -q '^KU_J9MSQD54$' "${TMP_DIR}/data/cluster/adminlist.txt"
grep -q '^KU_0PX1vpn8$' "${TMP_DIR}/data/cluster/adminlist.txt"
echo "PASS: set_admin.sh writes adminlist.txt"
```

- [ ] **Step 2: Write the failing access-list test**

```bash
#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/env" "${TMP_DIR}/data/cluster"
cat > "${TMP_DIR}/env/admins.txt" <<'EOF'
KU_J9MSQD54
EOF
cat > "${TMP_DIR}/env/whitelist.txt" <<'EOF'
KU_0PX1vpn8
EOF
cat > "${TMP_DIR}/env/blocklist.txt" <<'EOF'
KU_BLOCK12345
EOF

set +e
ADMINS_FILE="${TMP_DIR}/env/admins.txt" \
WHITELIST_FILE="${TMP_DIR}/env/whitelist.txt" \
BLOCKLIST_FILE="${TMP_DIR}/env/blocklist.txt" \
CLUSTER_DATA_DIR="${TMP_DIR}/data/cluster" \
bash scripts/set_access_lists.sh > "${TMP_DIR}/out.log" 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -ne 0 ]]; then
  cat "${TMP_DIR}/out.log"
  echo "Expected set_access_lists.sh to succeed"
  exit 1
fi

grep -q '^KU_J9MSQD54$' "${TMP_DIR}/data/cluster/adminlist.txt"
grep -q '^KU_0PX1vpn8$' "${TMP_DIR}/data/cluster/whitelist.txt"
grep -q '^KU_BLOCK12345$' "${TMP_DIR}/data/cluster/blocklist.txt"
echo "PASS: set_access_lists.sh writes all list files"
```

- [ ] **Step 3: Run tests to verify RED state**

Run:
```bash
bash tests/smoke/test_set_admin_script.sh
bash tests/smoke/test_set_access_lists_script.sh
```
Expected: FAIL because scripts do not exist yet.

- [ ] **Step 4: Commit test scaffolding**

```bash
git add tests/smoke/test_set_admin_script.sh tests/smoke/test_set_access_lists_script.sh
git commit -m "test: add failing smoke tests for admin and access list scripts"
```

### Task 2: Implement admin/access list scripts and source files

**Files:**
- Create: `env/admins.txt`
- Create: `env/whitelist.txt`
- Create: `env/blocklist.txt`
- Create: `scripts/set_admin.sh`
- Create: `scripts/set_access_lists.sh`

- [ ] **Step 1: Add default access source files**

```text
# env/admins.txt
KU_J9MSQD54
KU_0PX1vpn8
```

```text
# env/whitelist.txt
# Optional whitelist KU IDs, one per line
```

```text
# env/blocklist.txt
# Optional blocklist KU IDs, one per line
```

- [ ] **Step 2: Implement `scripts/set_admin.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

ADMINS_FILE="${ADMINS_FILE:-env/admins.txt}"
CLUSTER_DATA_DIR="${CLUSTER_DATA_DIR:-data/cluster}"
TARGET_FILE="${CLUSTER_DATA_DIR}/adminlist.txt"

if [[ ! -f "${ADMINS_FILE}" ]]; then
  echo "ERROR: ADMINS_FILE not found: ${ADMINS_FILE}" >&2
  exit 1
fi

mkdir -p "${CLUSTER_DATA_DIR}"
grep -Ev '^\s*($|#)' "${ADMINS_FILE}" | sed 's/[[:space:]]//g' > "${TARGET_FILE}"

echo "Admin list updated:"
cat "${TARGET_FILE}"
```

- [ ] **Step 3: Implement `scripts/set_access_lists.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

ADMINS_FILE="${ADMINS_FILE:-env/admins.txt}"
WHITELIST_FILE="${WHITELIST_FILE:-env/whitelist.txt}"
BLOCKLIST_FILE="${BLOCKLIST_FILE:-env/blocklist.txt}"
CLUSTER_DATA_DIR="${CLUSTER_DATA_DIR:-data/cluster}"

if [[ ! -f "${ADMINS_FILE}" ]]; then
  echo "ERROR: ADMINS_FILE not found: ${ADMINS_FILE}" >&2
  exit 1
fi

mkdir -p "${CLUSTER_DATA_DIR}"
[[ -f "${WHITELIST_FILE}" ]] || : > "${WHITELIST_FILE}"
[[ -f "${BLOCKLIST_FILE}" ]] || : > "${BLOCKLIST_FILE}"

grep -Ev '^\s*($|#)' "${ADMINS_FILE}" | sed 's/[[:space:]]//g' > "${CLUSTER_DATA_DIR}/adminlist.txt"
grep -Ev '^\s*($|#)' "${WHITELIST_FILE}" | sed 's/[[:space:]]//g' > "${CLUSTER_DATA_DIR}/whitelist.txt"
grep -Ev '^\s*($|#)' "${BLOCKLIST_FILE}" | sed 's/[[:space:]]//g' > "${CLUSTER_DATA_DIR}/blocklist.txt"

echo "Access lists updated:"
echo "  ${CLUSTER_DATA_DIR}/adminlist.txt"
echo "  ${CLUSTER_DATA_DIR}/whitelist.txt"
echo "  ${CLUSTER_DATA_DIR}/blocklist.txt"
```

- [ ] **Step 4: Run tests to verify GREEN state**

Run:
```bash
chmod +x scripts/set_admin.sh scripts/set_access_lists.sh tests/smoke/test_set_admin_script.sh tests/smoke/test_set_access_lists_script.sh
bash tests/smoke/test_set_admin_script.sh
bash tests/smoke/test_set_access_lists_script.sh
```
Expected: PASS.

- [ ] **Step 5: Commit implementation**

```bash
git add env/admins.txt env/whitelist.txt env/blocklist.txt scripts/set_admin.sh scripts/set_access_lists.sh
git commit -m "feat: add admin whitelist blocklist management scripts"
```

### Task 3: Add optional compose service and README security/runbook updates

**Files:**
- Modify: `docker-compose.yml`
- Modify: `README.md`
- Create: `tests/smoke/test_readme_access_controls.sh`

- [ ] **Step 1: Write failing README test**

```bash
#!/usr/bin/env bash
set -euo pipefail

grep -q "Integrated Admin, Whitelist, and Blocklist controls" README.md
grep -q "bash scripts/set_admin.sh" README.md
grep -q "bash scripts/set_access_lists.sh" README.md
grep -q "access-manager" README.md
echo "PASS: README documents access controls"
```

- [ ] **Step 2: Run test to verify RED state**

Run:
```bash
bash tests/smoke/test_readme_access_controls.sh
```
Expected: FAIL before README update.

- [ ] **Step 3: Update compose and README**

```yaml
# docker-compose.yml service to add under tools profile
  access-manager:
    image: dst-dedicated:latest
    env_file:
      - ./env/.env
    command: ["/workspace/scripts/set_access_lists.sh"]
    volumes:
      - ./:/workspace
      - ./data/cluster:/home/dst/.klei/DoNotStarveTogether/${DST_CLUSTER_NAME}
    profiles:
      - tools
```

```markdown
## Security / Bao mat

- Integrated Admin, Whitelist, and Blocklist controls.
- Configure IDs in:
  - `env/admins.txt`
  - `env/whitelist.txt`
  - `env/blocklist.txt`
- Apply on host:
  - `bash scripts/set_admin.sh`
  - `bash scripts/set_access_lists.sh`
- Apply via Docker tools profile:
  - `docker compose --profile tools run --rm access-manager`
```

- [ ] **Step 4: Run docs smoke tests**

Run:
```bash
bash tests/smoke/test_docs_and_env.sh
bash tests/smoke/test_readme_mod_update_flow.sh
bash tests/smoke/test_readme_features_architecture.sh
bash tests/smoke/test_readme_detailed_structure.sh
bash tests/smoke/test_readme_access_controls.sh
```
Expected: PASS.

- [ ] **Step 5: Commit docs/compose updates**

```bash
git add docker-compose.yml README.md tests/smoke/test_readme_access_controls.sh
git commit -m "docs: add integrated access control runbook and optional compose service"
```
