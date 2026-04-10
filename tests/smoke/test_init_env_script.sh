#!/usr/bin/env bash
set -euo pipefail

if [[ -f scripts/init_env.sh ]]; then
  echo "Expected project to avoid env creation helper scripts"
  exit 1
fi

grep -q "vi env/.env" README.md
if grep -q "cp env/.env.example env/.env" README.md; then
  echo "Expected README to avoid create/copy env step"
  exit 1
fi

echo "PASS: project enforces update-only env token workflow"
