#!/usr/bin/env bash
set -euo pipefail

grep -q "## Features" README.md
grep -q "## Architecture" README.md
grep -q "## Runtime Services" README.md
grep -q "## Component Flow" README.md
grep -q "docker compose up -d --build" README.md
grep -q "bash scripts/update_mods.sh" README.md
echo "PASS: detailed readme structure and command flow present"
