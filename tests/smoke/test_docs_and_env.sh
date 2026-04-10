#!/usr/bin/env bash
set -euo pipefail

grep -q "docker compose up -d --build" README.md
if grep -q "cp env/.env.example env/.env" README.md; then
  echo "Expected README to avoid create/copy env step"
  exit 1
fi
grep -q "macOS" README.md
grep -q "Linux" README.md
grep -q "Windows" README.md
grep -Eq "WSL|Git Bash" README.md
grep -q "DST_CLUSTER_TOKEN=" env/.env.example
grep -q "^env/.env$" .gitignore
echo "PASS: docs and secret handling files present"
