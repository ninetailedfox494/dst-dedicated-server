#!/usr/bin/env bash
set -euo pipefail

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

echo "Stopping shards..."
compose_cmd stop dst-master dst-caves

echo "Running mod updater..."
compose_cmd --profile tools run --rm mod-updater

echo "Starting shards..."
compose_cmd up -d dst-master dst-caves

echo "Done. Check logs with:"
echo "  docker compose logs -f dst-master"
echo "  docker compose logs -f dst-caves"
