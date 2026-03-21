#!/usr/bin/env bash
# Simple coverage gate for lib/views/settings_view.dart
# Exits 0 when coverage >= 95.0, non-zero otherwise.

set -eu

LCOV_FILE="coverage/lcov.info"
if [ ! -f "$LCOV_FILE" ]; then
  echo "Coverage file not found: $LCOV_FILE"
  exit 2
fi

LCOV_FILE="coverage/lcov.info"
if [ ! -f "$LCOV_FILE" ]; then
  echo "Coverage file not found: $LCOV_FILE"
  exit 2
fi

# Robustly extract LF and LH for the settings_view.dart SF record.
# Accept SF:lib/... or SF:/absolute/path/.../lib/... so we match any SF line that
# ends with lib/views/settings_view.dart
read -r LF LH <<EOF
$(awk '/^SF:.*lib\/views\/settings_view\.dart$/ { in_record=1; next } in_record && /^LF:/ { lf=substr($0,4) } in_record && /^LH:/ { lh=substr($0,4); print lf " " lh; exit }' "$LCOV_FILE")
EOF

if [ -z "$LF" ] || [ -z "$LH" ]; then
  echo "Could not find coverage record for $LCOV_FILE -> lib/views/settings_view.dart"
  exit 3
fi

# Compute percentage with awk for consistent formatting
PCT=$(awk "BEGIN { printf \"%.2f\", ($LH / $LF) * 100 }")

echo "settings_view.dart coverage: $PCT% ($LH/$LF)"

THRESH=95.0
if awk "BEGIN{exit !($PCT >= $THRESH)}"; then
  echo "Coverage threshold met"
  exit 0
else
  echo "Coverage threshold NOT met (need >= $THRESH%)"
  exit 1
fi
  exit 1
