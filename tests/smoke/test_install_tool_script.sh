#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="install_tool.sh"

if [[ ! -f "${SCRIPT_PATH}" ]]; then
  echo "Expected ${SCRIPT_PATH} to exist"
  exit 1
fi

grep -q '^#!/usr/bin/env bash$' "${SCRIPT_PATH}"
grep -q 'https://download.docker.com/linux/ubuntu' "${SCRIPT_PATH}"
grep -q 'docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin' "${SCRIPT_PATH}"
if grep -q 'git clone' "${SCRIPT_PATH}"; then
  echo "Expected install_tool.sh to avoid repository cloning"
  exit 1
fi
grep -q 'docker compose version' "${SCRIPT_PATH}"

echo "PASS: install_tool.sh configures tools without clone behavior"
