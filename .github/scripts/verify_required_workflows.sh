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
WORKFLOWS_API="https://api.github.com/repos/${REPO}/actions/workflows"

missing=0

for wf in "$@"; do
  echo "Checking workflow: '$wf' for commit $SHA"
  # If wf looks like a workflow filename (ends with .yml or .yaml), resolve to workflow_id
  workflow_id=""
  if echo "$wf" | grep -E "\.ya?ml$" >/dev/null 2>&1; then
    # Try to fetch workflow metadata by filename
    wresp=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "${WORKFLOWS_API}/$wf" || true)
    workflow_id=$(echo "$wresp" | jq -r '.id // empty' || true)
    if [ -n "$workflow_id" ]; then
      echo "Resolved workflow file '$wf' -> id=$workflow_id"
    else
      echo "Warning: could not resolve workflow file '$wf' to an id; falling back to name matching"
    fi
  fi
  # Query recent runs and look for matching head_sha and workflow name (API uses 'name').
  # If a run is in-progress the API may report a null conclusion; poll briefly to allow it to finish.
  # Allow overrides via environment, but increase defaults to tolerate CI timing
  POLL_RETRIES=${POLL_RETRIES:-30}
  POLL_INTERVAL=${POLL_INTERVAL:-10}
  conclusion=""
  for attempt in $(seq 0 "$POLL_RETRIES"); do
    resp=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "${API_URL}?per_page=200") || resp=""
    # If we resolved a workflow_id from a filename, prefer matching by workflow_id and head_sha
    if [ -n "$workflow_id" ]; then
      # Prefer the first non-null conclusion for matching runs (skip in-progress/null conclusions)
      conclusion=$(echo "$resp" | jq -r --arg id "$workflow_id" --arg sha "$SHA" '([.workflow_runs[] | select((.workflow_id|tostring)==$id and .head_sha==$sha and (.conclusion != null)) | .conclusion] | .[0])') || conclusion=""
    else
      # Find runs matching either .name or legacy .workflow_name and the head_sha; take the first match's conclusion
      # Prefer runs with a non-null conclusion to avoid picking an in-progress run
      conclusion=$(echo "$resp" | jq -r --arg wf "$wf" --arg sha "$SHA" '([.workflow_runs[] | select((.name==$wf or .workflow_name==$wf) and .head_sha==$sha and (.conclusion != null)) | .conclusion] | .[0])') || conclusion=""
    fi

    if [ -n "$conclusion" ] && [ "$conclusion" != "null" ]; then
      break
    fi

    # If not found or still null, and we have attempts left, sleep then retry
    if [ "$attempt" -lt "$POLL_RETRIES" ]; then
      sleep "$POLL_INTERVAL"
    fi
  done

  # debug: show what conclusions were found (for troubleshooting)
  if [ -z "$conclusion" ] || [ "$conclusion" == "null" ]; then
    # If no run matched the exact merge commit SHA (or it's still in-progress), try to find any pull
    # requests associated with that commit and check their head SHAs (CI often runs on PR heads).
    echo "Debug: no conclusion found for workflow '$wf' at $SHA; checking associated PR head SHAs and recent runs..."
    # Show recent runs for this workflow name to aid debugging (first 20)
    echo "$resp" | jq -r --arg wf "$wf" '[.workflow_runs[] | select(.name==$wf or .workflow_name==$wf) | {name:.name,workflow_name:.workflow_name,sha:.head_sha,conclusion:.conclusion,created_at:.created_at}][0:20]'

    prs=$(curl -s -H "Accept: application/vnd.github.groot-preview+json" -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${REPO}/commits/${SHA}/pulls") || true
    pr_shas=$(echo "$prs" | jq -r '.[].head.sha' || true)
    for pr_sha in $pr_shas; do
      if [ -z "$pr_sha" ]; then
        continue
      fi
      echo "Debug: checking PR head sha $pr_sha for workflow '$wf'"
      # Poll for PR-head run conclusions as well (allow short race window)
      for attempt in $(seq 0 "$POLL_RETRIES"); do
        resp=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" "${API_URL}?per_page=200") || resp=""
        # Prefer non-null conclusions from PR-head runs as well
        concl2=$(echo "$resp" | jq -r --arg wf "$wf" --arg sha "$pr_sha" '([.workflow_runs[] | select((.name==$wf or .workflow_name==$wf) and .head_sha==$sha and (.conclusion != null)) | .conclusion] | .[0])') || true
        if [ -n "$concl2" ] && [ "$concl2" != "null" ]; then
          conclusion="$concl2"
          break 2
        fi
        if [ "$attempt" -lt "$POLL_RETRIES" ]; then
          sleep "$POLL_INTERVAL"
        fi
      done
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
