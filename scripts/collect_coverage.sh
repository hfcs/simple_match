#!/usr/bin/env bash
set -euo pipefail

# Collect coverage for VM and/or Chrome web tests.
# Usage:
#   MODE=vm ./scripts/collect_coverage.sh
#   MODE=web ./scripts/collect_coverage.sh
#   MODE=combined ./scripts/collect_coverage.sh
#   MODE=merge ./scripts/collect_coverage.sh

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

MODE=${MODE:-combined}
CHUNKS=${CHUNKS:-2}

echo "Collect coverage mode: $MODE"

echo "Ensuring bundled fonts are present (download if needed)"
# If the downloader script exists, run it via bash (don't rely on the executable bit in CI)
if [ -f "$(pwd)/tool/download_fonts.sh" ]; then
  echo "Found tool/download_fonts.sh — running to fetch required fonts..."
  bash tool/download_fonts.sh || echo "Warning: download_fonts.sh failed; continuing (may fail later)"
else
  echo "No download script found at tool/download_fonts.sh; ensure assets/fonts/... exists if required"
fi

if [[ "$MODE" == "vm" || "$MODE" == "combined" ]]; then
  echo "Running VM tests..."
  flutter test --coverage
  mv coverage/lcov.info coverage/lcov.vm.info
fi

if [[ "$MODE" == "web" || "$MODE" == "combined" ]]; then
  echo "Enabling web and running tests on Chrome in chunks..."
  flutter config --enable-web
  echo "Using CHUNKS=$CHUNKS"

  # Ensure helper script is present
  if [ ! -x "$(pwd)/scripts/run_web_tests_chunk.sh" ]; then
    chmod +x "$(pwd)/scripts/run_web_tests_chunk.sh" || true
  fi

  rm -rf test_artifacts || true
  mkdir -p test_artifacts

  PIDS=()
  for i in $(seq 0 $((CHUNKS-1))); do
    echo "Starting web chunk $i"
    ./scripts/run_web_tests_chunk.sh "$i" "$CHUNKS" "$(pwd)/test_artifacts/web_chunk_$i" &
    PIDS+=("$!")
  done

  for pid in "${PIDS[@]}"; do
    wait "$pid" || true
  done

  # Extract any produced coverage.lcov files from chunk artifacts
  for a in test_artifacts/web_chunk_*/coverage.lcov; do
    if [ -f "$a" ]; then
      echo "Found chunk coverage: $a"
    fi
  done

  # Move any single coverage.lcov produced by flutter into coverage/lcov.chrome.info if present
  if [ -f coverage/lcov.info ]; then
    mv coverage/lcov.info coverage/lcov.chrome.info || true
  fi
fi

if [[ "$MODE" == "merge" ]]; then
  echo "Merge-only mode selected. Skipping test execution."
fi

if [[ "$MODE" == "combined" || "$MODE" == "merge" ]]; then
  echo "Merging LCOV files..."
  if [ -f coverage/lcov.chrome.info ]; then
    if command -v lcov >/dev/null 2>&1; then
      if [ -f coverage/lcov.vm.info ]; then
        lcov -a coverage/lcov.vm.info -a coverage/lcov.chrome.info -o coverage/lcov.combined.info
        LCOV_IN=coverage/lcov.combined.info
      else
        echo "Warning: coverage/lcov.vm.info not found; using coverage/lcov.chrome.info only"
        LCOV_IN=coverage/lcov.chrome.info
      fi
    else
      echo "Warning: 'lcov' not found; skipping LCOV merge and HTML generation"
      echo "Coverage files present at coverage/lcov.vm.info and coverage/lcov.chrome.info (if any)"
      exit 0
    fi
  else
    if [[ "$MODE" == "combined" ]]; then
      LCOV_IN=coverage/lcov.vm.info
    else
      echo "No web coverage produced; expected coverage/lcov.chrome.info" >&2
      exit 1
    fi
  fi
elif [[ "$MODE" == "vm" ]]; then
  LCOV_IN=coverage/lcov.vm.info
elif [[ "$MODE" == "web" ]]; then
  if [ -f coverage/lcov.chrome.info ]; then
    LCOV_IN=coverage/lcov.chrome.info
  else
    echo "No web coverage produced; expected coverage/lcov.chrome.info" >&2
    exit 1
  fi
else
  echo "Unknown MODE=$MODE" >&2
  exit 1
fi

echo "Filtering LCOV..."
mkdir -p coverage
if [ -x tools/filter_lcov.sh ]; then
  bash tools/filter_lcov.sh "$LCOV_IN" coverage/lcov.filtered.info
else
  cp "$LCOV_IN" coverage/lcov.filtered.info
fi

echo "Generating HTML..."
if command -v genhtml >/dev/null 2>&1; then
  genhtml -o coverage/html coverage/lcov.filtered.info
else
  echo "Warning: 'genhtml' not found; skipping HTML generation"
  echo "Filtered LCOV available at coverage/lcov.filtered.info"
  exit 0
fi

echo "Coverage generated at coverage/html/index.html"
