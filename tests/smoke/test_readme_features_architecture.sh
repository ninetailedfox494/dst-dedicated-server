#!/usr/bin/env bash
set -euo pipefail

grep -q "## Features" README.md
grep -q "## Architecture" README.md
grep -q "dst-master" README.md
grep -q "mod-updater" README.md
echo "PASS: features and architecture sections exist"
