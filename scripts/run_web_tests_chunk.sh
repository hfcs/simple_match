#!/usr/bin/env bash
set -euo pipefail

# Usage: run_web_tests_chunk.sh <chunk_index> <total_chunks>
# chunk_index: zero-based index (0..total_chunks-1)
# total_chunks: number of parallel chunks

CHUNK_INDEX=${1:-0}
TOTAL_CHUNKS=${2:-1}
OUTDIR=${3:-"$PWD/test_artifacts/web_chunk_${CHUNK_INDEX}"}
mkdir -p "$OUTDIR"

echo "Running web tests chunk ${CHUNK_INDEX}/${TOTAL_CHUNKS} -> output: $OUTDIR"

# Find all test files (stable sort)
ALL_TESTS=()
while IFS= read -r f; do
  ALL_TESTS+=("$f")
done < <(find test -type f -name "*_test.dart" | sort)

if [ ${#ALL_TESTS[@]} -eq 0 ]; then
  echo "No test files found under test/"
  exit 0
fi

# Select files for this chunk by modulo allocation
SELECTED=()
for i in "${!ALL_TESTS[@]}"; do
  if (( i % TOTAL_CHUNKS == CHUNK_INDEX )); then
    SELECTED+=("${ALL_TESTS[$i]}")
  fi
done

echo "Selected ${#SELECTED[@]} tests for this chunk"

# Run each test file sequentially. Capture per-test diagnostics.
for tf in "${SELECTED[@]}"; do
  echo "=== Running test: $tf ==="
  TEST_BASENAME=$(basename "$tf")
  LOG_PREFIX="$OUTDIR/${TEST_BASENAME//.dart/}"

  # Run the test (per-file coverage collection happens inside flutter test)
  TEST_EXIT=0
  if command -v timeout >/dev/null 2>&1; then
    # Use GNU timeout with a kill-after to ensure children are reaped
    timeout --kill-after=30s 10m flutter test ${FLUTTER_TEST_ARGS:-} -d chrome --coverage -v "$tf" >"${LOG_PREFIX}.log" 2>&1 || TEST_EXIT=$?;
  else
    echo "warning: 'timeout' not found; running flutter without enforced timeout" >"${LOG_PREFIX}.log"
    flutter test ${FLUTTER_TEST_ARGS:-} -d chrome --coverage -v "$tf" >>"${LOG_PREFIX}.log" 2>&1 || TEST_EXIT=$?;
  fi
  echo "exit=$TEST_EXIT" >"${LOG_PREFIX}.exit"

  # Always collect lightweight diagnostics after each test
  echo "-- /proc/meminfo --" >"${LOG_PREFIX}.meminfo"
  if [ -r /proc/meminfo ]; then cat /proc/meminfo >>"${LOG_PREFIX}.meminfo"; else echo "no /proc/meminfo" >>"${LOG_PREFIX}.meminfo"; fi

  echo "-- ps top RSS --" >"${LOG_PREFIX}.ps"
  # Prefer GNU ps sorting on Linux, fall back to portable invocation on macOS/BSD
  if [ "$(uname -s)" = "Linux" ]; then
    ps aux --sort=-rss | head -n 40 >>"${LOG_PREFIX}.ps" || true
  else
    ps aux | head -n 40 >>"${LOG_PREFIX}.ps" || true
  fi

  echo "-- last dmesg --" >"${LOG_PREFIX}.dmesg"
  # dmesg --ctime is Linux-specific and may require privileges on macOS; only run on Linux
  if [ "$(uname -s)" = "Linux" ] && command -v dmesg >/dev/null 2>&1; then
    dmesg --ctime | tail -n 200 >>"${LOG_PREFIX}.dmesg" || true
  else
    echo "no dmesg (non-linux or restricted)" >>"${LOG_PREFIX}.dmesg"
  fi

  # If the test was killed by signal 9, dump recent system state for debugging and continue
  if [ "$TEST_EXIT" -ne 0 ]; then
    echo "Test $tf failed or timed out (exit $TEST_EXIT)"
  fi
  # Copy any coverage produced by flutter into the per-test artifacts
  # Try several common locations for a coverage.lcov produced by flutter and copy the first one found.
  COVERAGE_FOUND=0
  # 1) local coverage directory
  if [ -f ./coverage/coverage.lcov ]; then
    cp ./coverage/coverage.lcov "${LOG_PREFIX}.coverage.lcov" || true
    COVERAGE_FOUND=1
  fi
  # 2) any coverage/coverage.lcov underneath the repo (first match)
  if [ "$COVERAGE_FOUND" -eq 0 ]; then
    cov=$(find . -type f -path '*/coverage/coverage.lcov' -print 2>/dev/null | head -n 1 || true)
    if [ -n "$cov" ] && [ -f "$cov" ]; then
      cp "$cov" "${LOG_PREFIX}.coverage.lcov" || true
      COVERAGE_FOUND=1
    fi
  fi
  # 3) some shims/tools write to /tmp/<something>/coverage/coverage.lcov — search /tmp shallowly
  if [ "$COVERAGE_FOUND" -eq 0 ]; then
    covtmp=$(find /tmp -maxdepth 3 -type f -name 'coverage.lcov' -print 2>/dev/null | head -n 1 || true)
    if [ -n "$covtmp" ] && [ -f "$covtmp" ]; then
      cp "$covtmp" "${LOG_PREFIX}.coverage.lcov" || true
      COVERAGE_FOUND=1
    fi
  fi
  if [ "$COVERAGE_FOUND" -eq 1 ]; then
    echo "coverage copied to ${LOG_PREFIX}.coverage.lcov" >"${LOG_PREFIX}.coverage.copyinfo" || true
    # remove the shared coverage dir if present so subsequent tests produce fresh files
    rm -rf coverage || true
  fi

  unset TEST_EXIT
  sleep 2
done

# Produce a tarball for artifact upload
tar -czf "$OUTDIR.tar.gz" -C "$(dirname "$OUTDIR")" "$(basename "$OUTDIR")"
echo "Chunk run complete. Archive: $OUTDIR.tar.gz"
