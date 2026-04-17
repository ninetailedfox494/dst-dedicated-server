#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

grep -q "resolve_steamclient_dylib" "${ROOT_DIR}/native-macos/scripts/_lib.sh"
grep -q "dst_runtime_binary" "${ROOT_DIR}/native-macos/scripts/_lib.sh"
grep -q "DST_SERVER_APP" "${ROOT_DIR}/native-macos/scripts/_lib.sh"
grep -q "DST_SERVER_STEAM_BIN64" "${ROOT_DIR}/native-macos/scripts/_lib.sh"
grep -q "SteamAppId=322330" "${ROOT_DIR}/native-macos/scripts/start.sh"
grep -q "SteamGameId=322330" "${ROOT_DIR}/native-macos/scripts/start.sh"
grep -q "DYLD_LIBRARY_PATH" "${ROOT_DIR}/native-macos/scripts/start.sh"
grep -q "DST_SERVER_STEAM_BIN64" "${ROOT_DIR}/native-macos/scripts/start.sh"
grep -q "runtime_binary" "${ROOT_DIR}/native-macos/scripts/start.sh"
grep -q "steamclient.dylib" "${ROOT_DIR}/native-macos/setup_dst_server.sh"
grep -q "dontstarve_dedicated_server_nullrenderer.app/Contents/MacOS/dontstarve_dedicated_server_nullrenderer" "${ROOT_DIR}/native-macos/setup_dst_server.sh"
grep -q "dst_server/bin64/dontstarve_dedicated_server_nullrenderer" "${ROOT_DIR}/native-macos/setup_dst_server.sh"
grep -q "bind_ip = 0.0.0.0" "${ROOT_DIR}/native-macos/data/cluster/cluster.ini"
grep -q "SteamGameServer_Init failed" "${ROOT_DIR}/native-macos/README.md"
echo "PASS: native macOS steam listing guardrails documented and scripted"
