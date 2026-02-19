#!/usr/bin/env bash
set -euo pipefail

# Usage: dispatch_and_poll.sh owner repo ref wf1.yml wf2.yml ...
# Requires GITHUB_TOKEN in environment.

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "GITHUB_TOKEN not set; export it and retry" >&2
  exit 2
fi

OWNER="$1"
REPO="$2"
REF="$3"
shift 3
WORKFLOWS=("$@")

echo "Dispatching workflows for ${OWNER}/${REPO} ref=${REF}: ${WORKFLOWS[*]}"

declare -A RUN_IDS

for wf in "${WORKFLOWS[@]}"; do
  echo "Dispatching $wf"
  curl -sS -X POST "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${wf}/dispatches" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "{\"ref\":\"${REF}\",\"inputs\":{\"merge_run\":\"${GITHUB_RUN_ID:-unknown}\"}}" || true
done

echo "Waiting for workflow runs to appear..."

for wf in "${WORKFLOWS[@]}"; do
  attempts=0
  while true; do
    attempts=$((attempts+1))
    # Query runs for the specific workflow and branch for precise matching
    runs_json=$(curl -sS -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${wf}/runs?event=workflow_dispatch&per_page=50&branch=${REF}")
    run_id=$(echo "$runs_json" | jq -r '.workflow_runs[0].id' || true)
    # Fallback: query runs for the workflow without branch filtering
    if [ -z "$run_id" ] || [ "$run_id" = "null" ]; then
      runs_json=$(curl -sS -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${OWNER}/${REPO}/actions/workflows/${wf}/runs?event=workflow_dispatch&per_page=50")
      run_id=$(echo "$runs_json" | jq -r '.workflow_runs[0].id' || true)
    fi
    if [ -n "$run_id" ] && [ "$run_id" != "null" ]; then
      echo "Found run for $wf -> $run_id"
      RUN_IDS[$wf]=$run_id
      break
    fi
    if [ $attempts -ge 30 ]; then
      echo "Timed out waiting for run for $wf" >&2
      exit 3
    fi
    sleep 4
  done
done

echo "Polling dispatched runs for completion..."

for wf in "${WORKFLOWS[@]}"; do
  run_id=${RUN_IDS[$wf]}
  echo "Polling $wf (run $run_id)"
  while true; do
    resp=$(curl -sS -H "Authorization: Bearer ${GITHUB_TOKEN}" \
      -H "Accept: application/vnd.github.v3+json" \
      "https://api.github.com/repos/${OWNER}/${REPO}/actions/runs/${run_id}")
    status=$(echo "$resp" | jq -r '.status')
    conclusion=$(echo "$resp" | jq -r '.conclusion')
    echo "run_id=$run_id status=$status conclusion=$conclusion"
    if [ "$status" = "completed" ]; then
      if [ "$conclusion" != "success" ]; then
        echo "Workflow $wf failed with conclusion: $conclusion" >&2
        exit 4
      fi
      echo "Workflow $wf succeeded."
      break
    fi
    sleep 10
  done
done

echo "All dispatched workflows completed successfully."
