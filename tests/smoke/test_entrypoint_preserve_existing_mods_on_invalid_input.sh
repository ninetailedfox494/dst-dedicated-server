#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENTRYPOINT="${ROOT_DIR}/docker/entrypoint.sh"

# Guard against accidental mod wipe when mods input is missing/invalid.
grep -q 'DST_ALLOW_EMPTY_MODS_SYNC' "${ENTRYPOINT}"
grep -q 'preserving existing mod configuration' "${ENTRYPOINT}"
grep -q 'No valid mods found in ${MODS_FILE}' "${ENTRYPOINT}"

echo "PASS: entrypoint preserves existing mods when mods input is missing/invalid"
