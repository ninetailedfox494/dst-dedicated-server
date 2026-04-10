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
EXTRACTED="$(mktemp)"
trap 'rm -f "${TMP_OUT}" "${EXTRACTED}"' EXIT

echo "return {" > "${TMP_OUT}"

while IFS= read -r line; do
  id="$(echo "${line}" | sed 's/#.*//' | sed 's/[[:space:]]//g')"
  [[ -n "${id}" ]] || continue

  modinfo="${MODS_DIR}/workshop-${id}/modinfo.lua"
  [[ -f "${modinfo}" ]] || { echo "ERROR: missing modinfo.lua for ${id} at ${modinfo}" >&2; exit 1; }

  echo "  [\"workshop-${id}\"] = { enabled = true, configuration_options = {" >> "${TMP_OUT}"
  if ! lua "${LUA_EXTRACTOR}" "${modinfo}" > "${EXTRACTED}"; then
    echo "ERROR: failed extracting defaults for mod ${id}" >&2
    exit 1
  fi
  while IFS= read -r kv; do
    [[ -n "${kv}" ]] || continue
    echo "    ${kv}," >> "${TMP_OUT}"
  done < "${EXTRACTED}"
  : > "${EXTRACTED}"
  echo "  } }," >> "${TMP_OUT}"
done < "${MODS_FILE}"

echo "}" >> "${TMP_OUT}"

mkdir -p "$(dirname "${TARGET_TEMPLATE}")"
mv "${TMP_OUT}" "${TARGET_TEMPLATE}"
trap - EXIT
echo "Updated ${TARGET_TEMPLATE}"
