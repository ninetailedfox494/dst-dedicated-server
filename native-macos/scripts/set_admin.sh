#!/usr/bin/env bash
set -euo pipefail

ADMINS_FILE="${ADMINS_FILE:-env/admins.txt}"
CLUSTER_DATA_DIR="${CLUSTER_DATA_DIR:-data/cluster}"
TARGET_FILE="${CLUSTER_DATA_DIR}/adminlist.txt"

if [[ ! -f "${ADMINS_FILE}" ]]; then
  echo "ERROR: ADMINS_FILE not found: ${ADMINS_FILE}" >&2
  exit 1
fi

mkdir -p "${CLUSTER_DATA_DIR}"
sed 's/#.*//' "${ADMINS_FILE}" | sed 's/[[:space:]]//g' | grep -v '^$' > "${TARGET_FILE}"

echo "Admin list updated:"
cat "${TARGET_FILE}"
