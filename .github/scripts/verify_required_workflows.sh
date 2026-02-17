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
  # Query recent runs and look for matching head_sha and workflow name (API uses 'name')
  resp=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "${API_URL}?per_page=200")
  # Find runs matching either .name or legacy .workflow_name and the head_sha; take the first match's conclusion
  conclusion=$(echo "$resp" | jq -r --arg wf "$wf" --arg sha "$SHA" '
    ([.workflow_runs[] | select((.name==$wf or .workflow_name==$wf) and .head_sha==$sha) | .conclusion] | .[0])'
  ) || true

  # debug: show what conclusions were found (for troubleshooting)
  if [ -z "$conclusion" ] || [ "$conclusion" == "null" ]; then
    # If no run matched the exact merge commit SHA, try to find any pull requests
    # associated with that commit and check their head SHAs (CI often runs on PR heads).
    echo "Debug: no conclusion found for workflow '$wf' at $SHA; checking associated PR head SHAs and recent runs..."
    echo "$resp" | jq -r '.workflow_runs[0:5] | map({name:.name,workflow_name:.workflow_name,sha:.head_sha,conclusion:.conclusion})'

    prs=$(curl -s -H "Accept: application/vnd.github.groot-preview+json" -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${REPO}/commits/${SHA}/pulls") || true
    pr_shas=$(echo "$prs" | jq -r '.[].head.sha' || true)
    for pr_sha in $pr_shas; do
      if [ -z "$pr_sha" ]; then
        continue
      fi
      echo "Debug: checking PR head sha $pr_sha for workflow '$wf'"
      concl2=$(echo "$resp" | jq -r --arg wf "$wf" --arg sha "$pr_sha" '([.workflow_runs[] | select((.name==$wf or .workflow_name==$wf) and .head_sha==$sha) | .conclusion] | .[0])') || true
      if [ -n "$concl2" ] && [ "$concl2" != "null" ]; then
        conclusion="$concl2"
        break
      fi
    done
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
