CI and preflight

Preflight check (what `merge-gate.yml` runs):

```bash
set -euo pipefail
files=(.github/workflows/coverage.yml .github/workflows/coverage-web.yml .github/workflows/integration-tests.yml .github/workflows/flutter-tests.yml .github/workflows/check-settings-view-coverage.yml)
for f in "${files[@]}"; do
  if [ ! -f "$f" ]; then
    echo "ERROR: missing $f" >&2
    exit 2
  fi
  if ! grep -q "workflow_call" "$f"; then
    echo "ERROR: $f does not declare workflow_call" >&2
    exit 3
  fi
done
```

Dispatching from a machine

```bash
export GITHUB_TOKEN=<token>
./.github/scripts/dispatch_and_poll.sh <owner> <repo> <ref> flutter-tests.yml integration-tests.yml coverage.yml coverage-web.yml check-settings-view-coverage.yml
```

Notes
- The controller expects workflows to expose `workflow_call` so they can be invoked and tested independently.
- Use the Actions API to inspect run status or artifacts when debugging.
