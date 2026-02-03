#!/usr/bin/env bash
set -euo pipefail

# setup_selfhosted_runner.sh
# Installs Flutter (stable) under /opt/flutter and ensures basic prerequisites are present.
# Intended to be run on an Ubuntu 22.04/24.04 self-hosted runner host.

if [[ $EUID -ne 0 ]]; then
  echo "Run this script with sudo: sudo ./setup_selfhosted_runner.sh" >&2
  exit 1
fi

FLUTTER_DIR="/opt/flutter"
FLUTTER_CHANNEL="stable"

echo "Updating apt and installing prerequisites..."
apt-get update -y
apt-get install -y git curl unzip xz-utils libglu1-mesa libgtk-3-0 libasound2 libnss3 libxss1 libxcb1 ca-certificates || true

if [[ -d "${FLUTTER_DIR}" ]]; then
  echo "Existing Flutter installation found at ${FLUTTER_DIR}, skipping clone." 
else
  echo "Cloning Flutter into ${FLUTTER_DIR} (this may take a minute)..."
  git clone https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
fi

echo "Checking out stable channel and updating..."
cd "${FLUTTER_DIR}"
git fetch --all --tags
git checkout "${FLUTTER_CHANNEL}"
./bin/flutter --version || true
./bin/flutter doctor --android-licenses >/dev/null 2>&1 || true

echo "Installing a global profile script at /etc/profile.d/flutter.sh"
cat > /etc/profile.d/flutter.sh <<EOF
export FLUTTER_ROOT=${FLUTTER_DIR}
export PATH=">$PATH:${FLUTTER_DIR}/bin"
EOF

chmod +x /etc/profile.d/flutter.sh || true

echo "Creating /var/crash (writable by all) for core capture if not present..."
mkdir -p /var/crash
chmod 1777 /var/crash

echo "Done. Tell the actions runner to run as the user 'runner' (or adjust the limits files)."
echo "Next: run scripts/configure_core_dumps.sh as root, then register the GitHub runner using scripts/register_github_runner.sh"

exit 0
