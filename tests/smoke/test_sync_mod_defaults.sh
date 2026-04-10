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
grep -q '\["enable_feature"\] = true' "${TMP_DIR}/docker/templates/modoverrides.lua.tmpl"
grep -q '\["limit"\] = 10' "${TMP_DIR}/docker/templates/modoverrides.lua.tmpl"
grep -q '\["label"\] = "abc"' "${TMP_DIR}/docker/templates/modoverrides.lua.tmpl"
echo "PASS: sync_mod_defaults.sh writes explicit defaults"
