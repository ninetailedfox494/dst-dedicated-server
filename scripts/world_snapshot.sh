#!/usr/bin/env bash
set -euo pipefail

WORLD_SNAPSHOT_PROJECT_ROOT="${WORLD_SNAPSHOT_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
WORLD_SNAPSHOT_CLUSTER_DIR="${WORLD_SNAPSHOT_CLUSTER_DIR:-${WORLD_SNAPSHOT_PROJECT_ROOT}/data/cluster}"
WORLD_SNAPSHOT_MASTER_DIR="${WORLD_SNAPSHOT_MASTER_DIR:-${WORLD_SNAPSHOT_PROJECT_ROOT}/data/master}"
WORLD_SNAPSHOT_CAVES_DIR="${WORLD_SNAPSHOT_CAVES_DIR:-${WORLD_SNAPSHOT_PROJECT_ROOT}/data/caves}"
WORLD_SNAPSHOT_BACKUP_DIR="${WORLD_SNAPSHOT_BACKUP_DIR:-${WORLD_SNAPSHOT_PROJECT_ROOT}/data/backups}"
WORLD_SNAPSHOT_SKIP_COMPOSE="${WORLD_SNAPSHOT_SKIP_COMPOSE:-0}"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/world_snapshot.sh backup [name]
  bash scripts/world_snapshot.sh restore <archive-path|archive-name|archive-prefix>
  bash scripts/world_snapshot.sh list
EOF
}

compose_cmd() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    echo "ERROR: docker compose command not found" >&2
    exit 1
  fi
}

maybe_stop_shards() {
  if [[ "${WORLD_SNAPSHOT_SKIP_COMPOSE}" == "1" ]]; then
    return
  fi
  compose_cmd stop dst-master dst-caves
}

maybe_start_shards() {
  if [[ "${WORLD_SNAPSHOT_SKIP_COMPOSE}" == "1" ]]; then
    return
  fi
  compose_cmd up -d dst-master dst-caves
}

require_world_dirs() {
  if [[ ! -d "${WORLD_SNAPSHOT_CLUSTER_DIR}" || ! -d "${WORLD_SNAPSHOT_MASTER_DIR}" || ! -d "${WORLD_SNAPSHOT_CAVES_DIR}" ]]; then
    echo "ERROR: world data directories are required:" >&2
    echo "  ${WORLD_SNAPSHOT_CLUSTER_DIR}" >&2
    echo "  ${WORLD_SNAPSHOT_MASTER_DIR}" >&2
    echo "  ${WORLD_SNAPSHOT_CAVES_DIR}" >&2
    exit 1
  fi
}

backup_world() {
  require_world_dirs
  mkdir -p "${WORLD_SNAPSHOT_BACKUP_DIR}"

  local name="${1:-world-backup}"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local archive="${WORLD_SNAPSHOT_BACKUP_DIR}/${name}-${timestamp}.tar.gz"

  maybe_stop_shards
  tar -czf "${archive}" -C "${WORLD_SNAPSHOT_PROJECT_ROOT}" data/cluster data/master data/caves
  maybe_start_shards

  echo "Backup created: ${archive}"
}

resolve_archive() {
  local input="${1}"
  if [[ -f "${input}" ]]; then
    echo "${input}"
    return
  fi

  local candidate="${WORLD_SNAPSHOT_BACKUP_DIR}/${input}"
  if [[ -f "${candidate}" ]]; then
    echo "${candidate}"
    return
  fi
  if [[ -f "${candidate}.tar.gz" ]]; then
    echo "${candidate}.tar.gz"
    return
  fi

  local latest
  latest="$(ls -1t "${WORLD_SNAPSHOT_BACKUP_DIR}/${input}-"*.tar.gz 2>/dev/null | head -n 1 || true)"
  if [[ -n "${latest}" ]]; then
    echo "${latest}"
    return
  fi

  echo "ERROR: archive not found: ${input}" >&2
  exit 1
}

restore_world() {
  local input="${1:-}"
  if [[ -z "${input}" ]]; then
    echo "ERROR: restore requires archive path or name" >&2
    usage
    exit 1
  fi

  local archive
  archive="$(resolve_archive "${input}")"
  mkdir -p "${WORLD_SNAPSHOT_PROJECT_ROOT}"

  maybe_stop_shards
  rm -rf "${WORLD_SNAPSHOT_CLUSTER_DIR}" "${WORLD_SNAPSHOT_MASTER_DIR}" "${WORLD_SNAPSHOT_CAVES_DIR}"
  tar -xzf "${archive}" -C "${WORLD_SNAPSHOT_PROJECT_ROOT}"
  maybe_start_shards

  echo "Restore completed from: ${archive}"
}

list_backups() {
  mkdir -p "${WORLD_SNAPSHOT_BACKUP_DIR}"
  ls -1 "${WORLD_SNAPSHOT_BACKUP_DIR}"/*.tar.gz 2>/dev/null || true
}

cmd="${1:-}"
case "${cmd}" in
  backup)
    shift
    backup_world "${1:-}"
    ;;
  restore)
    shift
    restore_world "${1:-}"
    ;;
  list)
    list_backups
    ;;
  *)
    usage
    exit 1
    ;;
esac
