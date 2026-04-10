#!/usr/bin/env bash
set -euo pipefail

grep -q "scripts/update_mods.sh" README.md
grep -q "^2798599672$" env/mods.txt
grep -q "^2189004162$" env/mods.txt
echo "PASS: README and mods list updated"
