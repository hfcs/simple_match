#!/usr/bin/env bash
set -euo pipefail

# register_github_runner.sh
# Template helper to download, configure and install the GitHub Actions runner as a service.
# Usage: sudo ./register_github_runner.sh OWNER REPO REGISTRATION_TOKEN RUNNER_NAME LABELS

if [[ $EUID -ne 0 ]]; then
  echo "This script should be run as root (it will create /opt/actions-runner and install a systemd service)." >&2
  exit 1
fi

if [[ $# -lt 5 ]]; then
  echo "Usage: $0 <owner> <repo> <registration_token> <runner_name> <labels>" >&2
  exit 2
fi

OWNER="$1"
REPO="$2"
TOKEN="$3"
RUNNER_NAME="$4"
LABELS="$5"

DESTDIR="/opt/actions-runner"
ARCHIVE="actions-runner-linux-x64.tar.gz"

mkdir -p "${DESTDIR}"
cd /tmp

echo "Downloading latest GitHub Actions runner..."
curl -sSLO "https://github.com/actions/runner/releases/latest/download/${ARCHIVE}"
tar xzf "${ARCHIVE}" -C "${DESTDIR}"

cd "${DESTDIR}"
echo "Configuring runner for https://github.com/${OWNER}/${REPO}"
./config.sh --url "https://github.com/${OWNER}/${REPO}" --token "${TOKEN}" --name "${RUNNER_NAME}" --labels "${LABELS}" --unattended || true

echo "Installing runner as a service and starting it..."
./svc.sh install || true
./svc.sh start || true

echo "Runner configured. Verify at: https://github.com/${OWNER}/${REPO}/settings/actions/runners"

exit 0
