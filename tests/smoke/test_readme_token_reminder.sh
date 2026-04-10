#!/usr/bin/env bash
set -euo pipefail

grep -q "DST_CLUSTER_TOKEN" README.md
grep -q "cluster_token.txt" README.md
grep -q "must replace REPLACE_WITH_REAL_TOKEN before first run" README.md
grep -q "Public template file" env/.env.example
echo "PASS: token reminder docs present"
