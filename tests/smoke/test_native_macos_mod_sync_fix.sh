#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

grep -q "sync_mod_configs" "${ROOT_DIR}/native-macos/scripts/_lib.sh"
grep -q "dst_server/mods/dedicated_server_mods_setup.lua" "${ROOT_DIR}/native-macos/scripts/_lib.sh"
grep -q "Documents/Klei/DoNotStarveTogether" "${ROOT_DIR}/native-macos/scripts/_lib.sh"
grep -q "sync_mod_configs" "${ROOT_DIR}/native-macos/scripts/start.sh"
grep -q "sync_mod_configs" "${ROOT_DIR}/native-macos/setup_dst_server.sh"
echo "PASS: native macOS mod config sync hooks are in place"
