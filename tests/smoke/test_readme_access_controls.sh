#!/usr/bin/env bash
set -euo pipefail

grep -q "Integrated Admin, Whitelist, and Blocklist controls" README.md
grep -q "bash scripts/set_admin.sh" README.md
grep -q "bash scripts/set_access_lists.sh" README.md
grep -q "access-manager" README.md
echo "PASS: README documents access controls"
