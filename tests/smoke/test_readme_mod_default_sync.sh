#!/usr/bin/env bash
set -euo pipefail

grep -q "bash scripts/sync_mod_defaults.sh" README.md
grep -q "fails if any modinfo.lua is missing" README.md
echo "PASS: README documents default sync command"
