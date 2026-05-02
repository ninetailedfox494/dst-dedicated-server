#!/usr/bin/env bash
set -euo pipefail

grep -Fq 'chown -R dst:dst /home/dst/.steam "${DST_CLUSTER_ROOT}" "${DST_INSTALL_DIR}"' docker/entrypoint.sh
echo "PASS: entrypoint chown targets steam, cluster root, and install dir"
