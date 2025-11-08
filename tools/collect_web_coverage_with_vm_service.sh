#!/usr/bin/env bash
set -euo pipefail

# Attempt to collect web coverage by connecting to a Dart VM service URI
# extracted from a verbose flutter web test log. This is a fallback when
# `flutter test --platform chrome --coverage` doesn't produce lcov.info.
#
# Usage: tools/collect_web_coverage_with_vm_service.sh <web_log> <out_lcov>
# Example: tools/collect_web_coverage_with_vm_service.sh coverage/web_test.log coverage/lcov.chrome.info

WEB_LOG=${1:-coverage/web_test.log}
OUT_LCOV=${2:-coverage/lcov.chrome.info}

if [ ! -f "$WEB_LOG" ]; then
  echo "Web log not found: $WEB_LOG"
  exit 1
fi

echo "Scanning $WEB_LOG for VM service URI..."

# Look for common patterns printed by the VM service/debugger in verbose logs.
# Examples include:
#  "The Dart VM service is listening on ws://127.0.0.1:PORT/abcd/"
#  "Debug service listening on ws://127.0.0.1:PORT/"
#  "Observatory listening on http://127.0.0.1:PORT/"

VM_URI=$(grep -oE "(ws|wss|http)://[0-9a-zA-Z:.\/-]+" "$WEB_LOG" | grep -E ":[0-9]{2,5}" | head -n 1 || true)

if [ -z "$VM_URI" ]; then
  echo "No VM service URI found in $WEB_LOG"
  echo "Tail of $WEB_LOG:" >&2
  tail -n 200 "$WEB_LOG" >&2 || true
  exit 2
fi

echo "Found VM service URI: $VM_URI"

echo "Ensuring 'coverage' package is available (dart pub global activate coverage)..."
if ! command -v dart >/dev/null 2>&1; then
  echo "dart executable not found in PATH. Please install Dart/Flutter SDK tools and ensure 'dart' is available." >&2
  exit 3
fi

if ! command -v collect_coverage >/dev/null 2>&1; then
  echo "Activating coverage package (this may take a moment)..."
  dart pub global activate coverage
fi

TMP_COV_JSON=coverage/web_coverage.json
TMP_COV_LCOV=coverage/web_coverage.lcov

echo "Collecting coverage from VM service URI..."
# collect_coverage options: --uri, --out, --wait-paused (not always needed), --resume-isolates
# We'll use a short timeout wrapper to avoid hanging indefinitely.
set +e
timeout 120s dart pub global run coverage:collect_coverage --uri="$VM_URI" --out="$TMP_COV_JSON" --wait-paused --resume-isolates
RC=$?
set -e

if [ $RC -ne 0 ] || [ ! -f "$TMP_COV_JSON" ]; then
  echo "collect_coverage failed (rc=$RC) or did not produce $TMP_COV_JSON" >&2
  tail -n 200 "$WEB_LOG" >&2 || true
  exit 4
fi

echo "Formatting coverage JSON to LCOV..."
# format_coverage accepts --packages; try common locations
PACKAGES_FILE=".packages"
if [ ! -f "$PACKAGES_FILE" ]; then
  # Newer Dart creates package_config.json under .dart_tool
  PACKAGES_FILE=".dart_tool/package_config.json"
fi

if ! command -v format_coverage >/dev/null 2>&1; then
  echo "format_coverage not found; activating coverage package (again)..."
  dart pub global activate coverage
fi

dart pub global run coverage:format_coverage --lcov --in="$TMP_COV_JSON" --out="$TMP_COV_LCOV" --packages="$PACKAGES_FILE" --report-on=lib || true

if [ ! -f "$TMP_COV_LCOV" ]; then
  echo "format_coverage failed to produce LCOV at $TMP_COV_LCOV" >&2
  exit 5
fi

echo "Moving LCOV to $OUT_LCOV"
mkdir -p "$(dirname "$OUT_LCOV")"
mv "$TMP_COV_LCOV" "$OUT_LCOV"

echo "Collected web coverage -> $OUT_LCOV"
exit 0
