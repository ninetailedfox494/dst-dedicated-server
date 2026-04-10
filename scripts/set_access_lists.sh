#!/usr/bin/env bash
set -euo pipefail

ADMINS_FILE="${ADMINS_FILE:-env/admins.txt}"
WHITELIST_FILE="${WHITELIST_FILE:-env/whitelist.txt}"
BLOCKLIST_FILE="${BLOCKLIST_FILE:-env/blocklist.txt}"
CLUSTER_DATA_DIR="${CLUSTER_DATA_DIR:-data/cluster}"

if [[ ! -f "${ADMINS_FILE}" ]]; then
  echo "ERROR: ADMINS_FILE not found: ${ADMINS_FILE}" >&2
  exit 1
fi

mkdir -p "${CLUSTER_DATA_DIR}"
[[ -f "${WHITELIST_FILE}" ]] || : > "${WHITELIST_FILE}"
[[ -f "${BLOCKLIST_FILE}" ]] || : > "${BLOCKLIST_FILE}"

sed 's/#.*//' "${ADMINS_FILE}" | sed 's/[[:space:]]//g' | grep -v '^$' > "${CLUSTER_DATA_DIR}/adminlist.txt"
sed 's/#.*//' "${WHITELIST_FILE}" | sed 's/[[:space:]]//g' | grep -v '^$' > "${CLUSTER_DATA_DIR}/whitelist.txt"
sed 's/#.*//' "${BLOCKLIST_FILE}" | sed 's/[[:space:]]//g' | grep -v '^$' > "${CLUSTER_DATA_DIR}/blocklist.txt"

echo "Access lists updated:"
echo "  ${CLUSTER_DATA_DIR}/adminlist.txt"
echo "  ${CLUSTER_DATA_DIR}/whitelist.txt"
echo "  ${CLUSTER_DATA_DIR}/blocklist.txt"
