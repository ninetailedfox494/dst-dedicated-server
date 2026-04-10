# Mod Default Config Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate explicit default `configuration_options` for all mods in `env/mods.txt` and write them into `docker/templates/modoverrides.lua.tmpl`.

**Architecture:** Add a one-time sync script that reads local downloaded `modinfo.lua` files for each workshop mod, extracts default config options, and serializes those defaults into the template. The script fails fast if any required mod metadata is missing and writes the target file atomically.

**Tech Stack:** Bash, Lua execution (`lua`), existing repo scripts/tests

---

### Task 1: Add failing smoke test for default-config sync

**Files:**
- Create: `tests/smoke/test_sync_mod_defaults.sh`
- Test: `scripts/sync_mod_defaults.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${TMP_DIR}/env" "${TMP_DIR}/data/mods/workshop-111" "${TMP_DIR}/docker/templates"
cat > "${TMP_DIR}/env/mods.txt" <<'EOF'
111
EOF
cat > "${TMP_DIR}/data/mods/workshop-111/modinfo.lua" <<'EOF'
name = "Test Mod"
configuration_options = {
  { name = "enable_feature", default = true },
  { name = "limit", default = 10 },
  { name = "label", default = "abc" },
}
EOF
cat > "${TMP_DIR}/docker/templates/modoverrides.lua.tmpl" <<'EOF'
return {}
EOF

set +e
MODS_FILE="${TMP_DIR}/env/mods.txt" \
MODS_DIR="${TMP_DIR}/data/mods" \
TARGET_TEMPLATE="${TMP_DIR}/docker/templates/modoverrides.lua.tmpl" \
bash scripts/sync_mod_defaults.sh > "${TMP_DIR}/out.log" 2>&1
STATUS=$?
set -e

if [[ ${STATUS} -ne 0 ]]; then
  cat "${TMP_DIR}/out.log"
  echo "Expected sync_mod_defaults.sh to succeed"
  exit 1
fi

grep -q 'workshop-111' "${TMP_DIR}/docker/templates/modoverrides.lua.tmpl"
grep -q 'enable_feature = true' "${TMP_DIR}/docker/templates/modoverrides.lua.tmpl"
grep -q 'limit = 10' "${TMP_DIR}/docker/templates/modoverrides.lua.tmpl"
grep -q 'label = "abc"' "${TMP_DIR}/docker/templates/modoverrides.lua.tmpl"
echo "PASS: sync_mod_defaults.sh writes explicit defaults"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_sync_mod_defaults.sh`  
Expected: FAIL because `scripts/sync_mod_defaults.sh` does not exist.

- [ ] **Step 3: Commit failing test**

```bash
git add tests/smoke/test_sync_mod_defaults.sh
git commit -m "test: add failing smoke test for mod default sync"
```

### Task 2: Implement sync script and Lua extractor

**Files:**
- Create: `scripts/sync_mod_defaults.sh`
- Create: `scripts/extract_mod_defaults.lua`
- Modify: `docker/templates/modoverrides.lua.tmpl`

- [ ] **Step 1: Create Lua extractor**

```lua
-- scripts/extract_mod_defaults.lua
local modinfo_path = arg[1]
assert(modinfo_path, "modinfo path required")

local env = {}
setmetatable(env, {
  __index = function(_, k) return rawget(_G, k) end
})

local chunk, err = loadfile(modinfo_path, "t", env)
if not chunk then
  io.stderr:write("ERROR: cannot load modinfo: " .. err .. "\n")
  os.exit(1)
end
chunk()

local opts = env.configuration_options or {}
local out = {}
for _, opt in ipairs(opts) do
  if type(opt) == "table" and opt.name ~= nil and opt.default ~= nil then
    out[#out + 1] = { name = opt.name, default = opt.default }
  end
end

local function to_lua(v)
  local t = type(v)
  if t == "boolean" or t == "number" then return tostring(v) end
  if t == "string" then return string.format("%q", v) end
  if t == "table" then
    local parts = {}
    for k, vv in pairs(v) do
      local key = type(k) == "string" and k .. " = " or "[" .. tostring(k) .. "] = "
      parts[#parts + 1] = key .. to_lua(vv)
    end
    return "{ " .. table.concat(parts, ", ") .. " }"
  end
  error("unsupported default type: " .. t)
end

for _, item in ipairs(out) do
  io.write(item.name .. "=" .. to_lua(item.default) .. "\n")
end
```

- [ ] **Step 2: Create sync script**

```bash
#!/usr/bin/env bash
set -euo pipefail

MODS_FILE="${MODS_FILE:-env/mods.txt}"
MODS_DIR="${MODS_DIR:-data/mods}"
TARGET_TEMPLATE="${TARGET_TEMPLATE:-docker/templates/modoverrides.lua.tmpl}"
LUA_EXTRACTOR="${LUA_EXTRACTOR:-scripts/extract_mod_defaults.lua}"

command -v lua >/dev/null 2>&1 || { echo "ERROR: lua is required" >&2; exit 1; }
[[ -f "${MODS_FILE}" ]] || { echo "ERROR: MODS_FILE not found: ${MODS_FILE}" >&2; exit 1; }
[[ -f "${LUA_EXTRACTOR}" ]] || { echo "ERROR: LUA_EXTRACTOR not found: ${LUA_EXTRACTOR}" >&2; exit 1; }

TMP_OUT="$(mktemp)"
trap 'rm -f "${TMP_OUT}"' EXIT

echo "return {" > "${TMP_OUT}"

while IFS= read -r line; do
  id="$(echo "${line}" | sed 's/#.*//' | sed 's/[[:space:]]//g')"
  [[ -n "${id}" ]] || continue

  modinfo="${MODS_DIR}/workshop-${id}/modinfo.lua"
  [[ -f "${modinfo}" ]] || { echo "ERROR: missing modinfo.lua for ${id} at ${modinfo}" >&2; exit 1; }

  echo "  [\"workshop-${id}\"] = { enabled = true, configuration_options = {" >> "${TMP_OUT}"
  while IFS= read -r kv; do
    k="${kv%%=*}"
    v="${kv#*=}"
    echo "    ${k} = ${v}," >> "${TMP_OUT}"
  done < <(lua "${LUA_EXTRACTOR}" "${modinfo}")
  echo "  } }," >> "${TMP_OUT}"
done < "${MODS_FILE}"

echo "}" >> "${TMP_OUT}"

mkdir -p "$(dirname "${TARGET_TEMPLATE}")"
mv "${TMP_OUT}" "${TARGET_TEMPLATE}"
trap - EXIT
echo "Updated ${TARGET_TEMPLATE}"
```

- [ ] **Step 3: Run test to verify it passes**

Run: `bash tests/smoke/test_sync_mod_defaults.sh`  
Expected: PASS with explicit defaults in output template.

- [ ] **Step 4: Ensure script executable**

Run: `chmod +x scripts/sync_mod_defaults.sh tests/smoke/test_sync_mod_defaults.sh`

- [ ] **Step 5: Commit implementation**

```bash
git add scripts/extract_mod_defaults.lua scripts/sync_mod_defaults.sh docker/templates/modoverrides.lua.tmpl tests/smoke/test_sync_mod_defaults.sh
git commit -m "feat: sync explicit mod default options into modoverrides template"
```

### Task 3: Add README command and failure behavior docs

**Files:**
- Modify: `README.md`
- Create: `tests/smoke/test_readme_mod_default_sync.sh`

- [ ] **Step 1: Write failing docs test**

```bash
#!/usr/bin/env bash
set -euo pipefail

grep -q "bash scripts/sync_mod_defaults.sh" README.md
grep -q "fails if any modinfo.lua is missing" README.md
echo "PASS: README documents default sync command"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/smoke/test_readme_mod_default_sync.sh`  
Expected: FAIL before README update.

- [ ] **Step 3: Update README**

```markdown
## Sync Mod Default Options

```bash
bash scripts/sync_mod_defaults.sh
```

This command reads defaults from downloaded `modinfo.lua` files and rewrites `docker/templates/modoverrides.lua.tmpl`.
It fails if any modinfo.lua is missing.
```

- [ ] **Step 4: Run docs tests**

Run:
```bash
bash tests/smoke/test_readme_mod_default_sync.sh
bash tests/smoke/test_readme_mod_update_flow.sh
```
Expected: PASS.

- [ ] **Step 5: Commit docs**

```bash
git add README.md tests/smoke/test_readme_mod_default_sync.sh
git commit -m "docs: add mod default sync runbook command"
```
