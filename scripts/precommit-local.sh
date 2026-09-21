#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

echo "Running local pre-commit checks: flutter test"
flutter test --coverage

echo "Local pre-commit checks passed."
