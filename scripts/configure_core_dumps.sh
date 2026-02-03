#!/usr/bin/env bash
set -euo pipefail

# configure_core_dumps.sh
# Configure kernel and system limits to enable core dumps for a self-hosted GitHub Actions runner.

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (sudo)." >&2
  exit 1
fi

CORE_PATTERN="/var/crash/core.%e.%p.%t"
LIMITS_FILE="/etc/security/limits.d/99-runner-limits.conf"
SYSCTL_FILE="/etc/sysctl.d/99-core.conf"

echo "Creating core output directory /var/crash and setting permissions..."
mkdir -p /var/crash
chmod 1777 /var/crash

echo "Writing sysctl settings to ${SYSCTL_FILE}"
cat > "${SYSCTL_FILE}" <<EOF
# Allow persistent core pattern for GitHub Actions runner diagnostics
kernel.core_pattern=${CORE_PATTERN}
kernel.core_uses_pid=1
EOF

echo "Applying sysctl settings..."
sysctl --system >/dev/null || true

echo "Writing PAM limits to ${LIMITS_FILE} (applies to login sessions)..."
cat > "${LIMITS_FILE}" <<EOF
# Allow unlimited core size for the actions runner user(s).
# Replace 'runner' with your runner user if different.
runner soft core unlimited
runner hard core unlimited
EOF

echo "Configuring systemd runner service drop-in to allow unlimited CORE for any actions runner service..."
mkdir -p /etc/systemd/system/actions.runner.service.d
cat > /etc/systemd/system/actions.runner.service.d/limits.conf <<'EOF'
[Service]
LimitCORE=infinity
EOF

echo "Reloading systemd daemon..."
systemctl daemon-reload || true

echo "Done. Verify with: ulimit -c (as runner user), sysctl kernel.core_pattern"

exit 0
