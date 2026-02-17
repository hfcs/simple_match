#!/usr/bin/env bash
# Verifies that a list of GitHub Actions workflow names each have a successful run
# for the provided commit SHA in the current repository.

set -euo pipefail

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "GITHUB_TOKEN must be provided in environment" >&2
  exit 2
fi

if [ -z "${REPO:-}" ]; then
  echo "REPO must be provided in environment (owner/repo)" >&2
  exit 2
fi

if [ -z "${SHA:-}" ]; then
  echo "SHA must be provided in environment (commit head sha)" >&2
  exit 2
fi

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <workflow-name> [<workflow-name> ...]" >&2
  exit 2
fi

API_URL="https://api.github.com/repos/${REPO}/actions/runs"

missing=0

for wf in "$@"; do
  echo "Checking workflow: '$wf' for commit $SHA"
  # Query recent runs and look for matching head_sha and workflow_name
  resp=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "${API_URL}?per_page=200")
  # Find runs matching both workflow name and head_sha; take the first match's conclusion
  conclusion=$(echo "$resp" | jq -r --arg wf "$wf" --arg sha "$SHA" '
    ([.workflow_runs[] | select(.workflow_name==$wf and .head_sha==$sha) | .conclusion] | .[0])'
  ) || true

  # debug: show what conclusions were found (for troubleshooting)
  if [ -z "$conclusion" ] || [ "$conclusion" == "null" ]; then
    echo "Debug: no conclusion found for workflow '$wf' at $SHA; sample runs:"
    echo "$resp" | jq -r '.workflow_runs[0:5] | map({name:.workflow_name,sha:.head_sha,conclusion:.conclusion})'
  fi

  if [ -z "$conclusion" ] || [ "$conclusion" == "null" ]; then
    echo "No run found for workflow '$wf' at commit $SHA"
    missing=1
    continue
  fi

  echo "Found conclusion for '$wf': $conclusion"
  if [ "$conclusion" != "success" ]; then
    echo "Required workflow '$wf' did not succeed for commit $SHA (conclusion=$conclusion)" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "One or more required workflows did not succeed for $SHA" >&2
  exit 3
fi

echo "All required workflows succeeded for $SHA"
exit 0
