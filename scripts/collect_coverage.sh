#!/usr/bin/env bash
set -euo pipefail

# Collect coverage for VM and Chrome, merge and generate HTML
# Usage: ./scripts/collect_coverage.sh

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

echo "Running VM tests..."
flutter test --coverage
mv coverage/lcov.info coverage/lcov.vm.info

echo "Enabling web and running tests on Chrome..."
flutter config --enable-web
# Ensure Chrome is available in PATH (CI should install it)
WEB_LOG=coverage/web_test.log
rm -f "$WEB_LOG"
echo "Running web tests on Chrome (logs -> $WEB_LOG)"
# If CHROME_EXECUTABLE not set, try a reasonable macOS default
if [ -z "${CHROME_EXECUTABLE-}" ]; then
  if [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    export CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    echo "Using CHROME_EXECUTABLE=$CHROME_EXECUTABLE"
  else
    echo "CHROME_EXECUTABLE not set and default macOS path not found; relying on PATH to find Chrome"
  fi
fi

echo "Flutter: $(flutter --version | head -n 1)"
echo "Which chrome: $(which google-chrome || which google-chrome-stable || which google-chrome-beta || echo 'not-found')"

# Try the device-id form first; some Flutter versions produce lcov with -d chrome
echo "Attempt: flutter test -d chrome --coverage -v"
flutter test -d chrome --coverage -v >"$WEB_LOG" 2>&1 || true

# If no lcov was produced, try --platform chrome with verbose logs (existing fallback)
if [ ! -f coverage/lcov.info ]; then
  echo "No lcov.info after -d chrome run, trying --platform chrome..." | tee -a "$WEB_LOG"
  flutter test --platform chrome --coverage -v >>"$WEB_LOG" 2>&1 || true
fi

# Move coverage if produced
if [ -f coverage/lcov.info ]; then
  mv coverage/lcov.info coverage/lcov.chrome.info
  echo "Chrome coverage captured -> coverage/lcov.chrome.info"
else
  echo "No coverage file produced by flutter test runs. Attempting VM-service fallback..." | tee -a "$WEB_LOG"
  # Attempt to collect coverage via VM service using our helper; it will read $WEB_LOG for the VM URI
  if [ -x "$(pwd)/tools/collect_web_coverage_with_vm_service.sh" ]; then
    if bash tools/collect_web_coverage_with_vm_service.sh "$WEB_LOG" coverage/lcov.chrome.info; then
      echo "VM-service fallback produced coverage/lcov.chrome.info"
    else
      echo "VM-service fallback failed. See $WEB_LOG and tools/collect_web_coverage_with_vm_service.sh for debug." | tee -a "$WEB_LOG"
    fi
  else
    echo "Fallback script not found or not executable: tools/collect_web_coverage_with_vm_service.sh" | tee -a "$WEB_LOG"
  fi
fi

echo "Merging LCOV files..."
if [ -f coverage/lcov.chrome.info ]; then
  lcov -a coverage/lcov.vm.info -a coverage/lcov.chrome.info -o coverage/lcov.combined.info
  LCOV_IN=coverage/lcov.combined.info
else
  LCOV_IN=coverage/lcov.vm.info
fi

echo "Filtering LCOV..."
mkdir -p coverage
if [ -x tools/filter_lcov.sh ]; then
  bash tools/filter_lcov.sh "$LCOV_IN" coverage/lcov.filtered.info
else
  cp "$LCOV_IN" coverage/lcov.filtered.info
fi

echo "Generating HTML..."
genhtml -o coverage/html coverage/lcov.filtered.info

echo "Coverage generated at coverage/html/index.html"
