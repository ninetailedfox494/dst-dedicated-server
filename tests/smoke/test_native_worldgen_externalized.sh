#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET="${ROOT_DIR}/native-macos/setup_dst_server.sh"

grep -q 'WORLDGEN_TEMPLATE="${PROJECT_ROOT}/env/worldgenoverride.txt"' "${TARGET}"
grep -q 'cp "${WORLDGEN_TEMPLATE}" "${MASTER_DIR}/worldgenoverride.lua"' "${TARGET}"
if grep -q 'cat > "${MASTER_DIR}/worldgenoverride.lua" <<'"'"'EOF'"'"'' "${TARGET}"; then
  echo "Found inline worldgen template in native setup script"
  exit 1
fi

echo "PASS: native worldgen template is externalized"
