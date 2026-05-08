#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TARGET_SETUP="${ROOT_DIR}/native-macos/setup_dst_server.sh"
TARGET_TEMPLATE="${ROOT_DIR}/native-macos/env/worldgenoverride.txt.template"

grep -q 'world_size = "__DST_WORLD_SIZE__"' "${TARGET_TEMPLATE}"
grep -q 'WORLDGEN_SIZE="${DST_WORLD_SIZE:-medium}"' "${TARGET_SETUP}"
grep -q 'sed "s/__DST_WORLD_SIZE__/${WORLDGEN_SIZE}/g"' "${TARGET_SETUP}"

echo "PASS: native setup world_size is injected from DST_WORLD_SIZE"
