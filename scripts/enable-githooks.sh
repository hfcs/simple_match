#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

echo "Setting git hooks path to .githooks for this repository (local config)"
git config core.hooksPath .githooks
echo "Done. To revert: git config --unset core.hooksPath"
