#!/usr/bin/env bash
set -euo pipefail

grep -q '^FROM ubuntu:24\.04$' docker/Dockerfile

if grep -nE "docker-compose[[:space:]]+(up|down|logs|run|restart|exec|ps|stop|version|--version)" README.md docker/README.md docker/setup/README.md TROUBLESHOOTING.md docker/setup/init_docker_env.sh >/dev/null; then
  echo "Expected docs/scripts to use 'docker compose' command style"
  exit 1
fi

grep -q "^  dst:" docker/docker-compose.yml

if grep -nE "^  dst-master:|^  dst-caves:" docker/docker-compose.yml >/dev/null; then
  echo "Expected legacy split shard service names to be removed"
  exit 1
fi

if grep -q '^version:' docker/docker-compose.yml; then
  echo "Expected compose file to omit legacy top-level version field"
  exit 1
fi

echo "PASS: Ubuntu 24.04 upgrade surfaces are aligned"
