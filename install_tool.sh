#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

require_cmd() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "ERROR: required command not found: ${cmd}" >&2
    exit 1
  fi
}

run_as_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    require_cmd sudo
    sudo "$@"
  fi
}

detect_user() {
  if [[ -n "${SUDO_USER:-}" ]]; then
    echo "${SUDO_USER}"
  else
    id -un
  fi
}

check_os() {
  if [[ ! -r /etc/os-release ]]; then
    echo "ERROR: cannot detect OS (missing /etc/os-release)" >&2
    exit 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "ERROR: this script supports Ubuntu only. Detected: ${ID:-unknown}" >&2
    exit 1
  fi
}

setup_docker_repo() {
  run_as_root install -m 0755 -d /etc/apt/keyrings
  run_as_root curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  run_as_root chmod a+r /etc/apt/keyrings/docker.asc

  # shellcheck disable=SC1091
  source /etc/os-release
  local arch codename
  arch="$(dpkg --print-architecture)"
  codename="${VERSION_CODENAME:-}"
  if [[ -z "${codename}" ]]; then
    echo "ERROR: unable to determine Ubuntu codename" >&2
    exit 1
  fi

  run_as_root bash -c "echo 'deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable' > /etc/apt/sources.list.d/docker.list"
}

install_packages() {
  run_as_root apt-get update
  run_as_root apt-get install -y ca-certificates curl git gnupg

  setup_docker_repo

  run_as_root apt-get update
  run_as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

configure_docker_group() {
  local user_name="$1"
  if ! getent group docker >/dev/null 2>&1; then
    run_as_root groupadd docker
  fi

  if id -nG "${user_name}" | grep -qw docker; then
    return
  fi

  run_as_root usermod -aG docker "${user_name}"
  echo "NOTICE: user '${user_name}' was added to docker group. Log out/in (or run 'newgrp docker') before using docker without sudo."
}

main() {
  check_os

  local target_user
  target_user="$(detect_user)"

  install_packages
  configure_docker_group "${target_user}"

  git --version
  docker --version
  docker compose version

  cat <<EOF
Done.
Next steps:
1. cd ${SCRIPT_DIR}/docker
2. bash setup/init_docker_env.sh
3. docker compose up -d
EOF
}

main "$@"
