#!/usr/bin/env bash
# Robust monitor for the Merge Gate workflow run for a given commit SHA
set -euo pipefail

GITHUB_TOKEN=${GITHUB_TOKEN:-}
if [ -z "$GITHUB_TOKEN" ]; then
  echo "ERROR: GITHUB_TOKEN must be set in environment" >&2
  exit 2
fi

REPO=${REPO:-}
if [ -z "$REPO" ]; then
  # derive from git remote
  REPO_URL=$(git remote get-url origin 2>/dev/null || true)
  if [ -z "$REPO_URL" ]; then
    echo "ERROR: could not determine git remote REPO; set REPO=owner/repo" >&2
    exit 3
  fi
  if echo "$REPO_URL" | grep -q "@github.com:"; then
    REPO=$(echo "$REPO_URL" | sed -E 's/.*@github.com:(.*)\.git/\1/')
  else
    REPO=$(echo "$REPO_URL" | sed -E 's#.*/github.com/([^/]+/[^/]+)(\.git)?#\1#')
  fi
fi

SHA=${1:-}
if [ -z "$SHA" ]; then
  SHA=$(git rev-parse --verify HEAD 2>/dev/null || true)
fi
if [ -z "$SHA" ]; then
  echo "ERROR: could not determine commit SHA; pass as first arg or run from a git repo" >&2
  exit 4
fi

API_BASE="https://api.github.com/repos/${REPO}/actions"
LOGDIR=${LOGDIR:-/tmp/monitor_merge_gate}
mkdir -p "$LOGDIR"
LOGFILE="$LOGDIR/monitor_${SHA}_$(date +%s).log"

echo "Monitor start: repo=$REPO sha=$SHA" | tee "$LOGFILE"

curl_opts=( -s -H "Authorization: token ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" )

echo "Fetching recent workflow runs..." | tee -a "$LOGFILE"
resp=$(curl "${curl_opts[@]}" "${API_BASE}/runs?per_page=200") || resp=""
echo "fetched $(echo "$resp" | jq -r '.workflow_runs|length // 0') runs" | tee -a "$LOGFILE"

run_id=$(echo "$resp" | jq -r --arg sha "$SHA" '.workflow_runs[] | select(.name=="Merge Gate" and .head_sha==$sha) | .id' | head -n1 || true)

if [ -z "$run_id" ] || [ "$run_id" = "null" ]; then
  echo "No Merge Gate run found for $SHA" | tee -a "$LOGFILE"
  echo "Recent Merge Gate runs:" | tee -a "$LOGFILE"
  echo "$resp" | jq -r '.workflow_runs[] | select(.name=="Merge Gate") | "id=\(.id) head_sha=\(.head_sha) status=\(.status) conclusion=\(.conclusion) url=\(.html_url)"' | tee -a "$LOGFILE"
  echo "Log file: $LOGFILE" >&2
  exit 5
fi

echo "Found Merge Gate run id=$run_id" | tee -a "$LOGFILE"

# poll until completed
MAX_POLL=${MAX_POLL:-60}
SLEEP=${SLEEP:-10}
count=0
while true; do
  count=$((count+1))
  run_json=$(curl "${curl_opts[@]}" "${API_BASE}/runs/${run_id}") || run_json="{}"
  status=$(echo "$run_json" | jq -r '.status // "unknown"')
  conclusion=$(echo "$run_json" | jq -r '.conclusion // "null"')
  echo "[poll:$count] status=$status conclusion=$conclusion" | tee -a "$LOGFILE"
  if [ "$status" = "completed" ]; then
    break
  fi
  if [ $count -ge $MAX_POLL ]; then
    echo "Timed out waiting for run to complete (polls=$count)" | tee -a "$LOGFILE"
    exit 6
  fi
  sleep "$SLEEP"
done

echo "Run completed: conclusion=$conclusion" | tee -a "$LOGFILE"

echo "Fetching jobs..." | tee -a "$LOGFILE"
jobs_json=$(curl "${curl_opts[@]}" "${API_BASE}/runs/${run_id}/jobs?per_page=200") || jobs_json="{}"
echo "$jobs_json" | jq -r '.jobs[] | "JOB: " + .name + " id=" + (.id|tostring) + " status=" + .status + " conclusion=" + (.conclusion//"null") + "\n  steps:\n" + ( .steps | map("    - " + .name + " | status=" + .status + " conclusion=" + (.conclusion//"null")) | join("\n") )' | tee -a "$LOGFILE"

echo "Downloading run logs zip..." | tee -a "$LOGFILE"
logs_zip="$LOGDIR/${run_id}_logs.zip"
curl -L "${curl_opts[@]}" "${API_BASE}/runs/${run_id}/logs" -o "$logs_zip" || true
if [ -f "$logs_zip" ]; then
  echo "Extracting logs to $LOGDIR/${run_id}_logs" | tee -a "$LOGFILE"
  mkdir -p "$LOGDIR/${run_id}_logs"
  unzip -o "$logs_zip" -d "$LOGDIR/${run_id}_logs" >/dev/null 2>&1 || true
  echo "Searching verifier output in logs..." | tee -a "$LOGFILE"
  grep -R -n -E "verify_required_workflows|Verify required workflows" "$LOGDIR/${run_id}_logs" | tee -a "$LOGFILE" || true
else
  echo "No logs zip at $logs_zip" | tee -a "$LOGFILE"
fi

echo "Monitor finished. Log file: $LOGFILE"
exit 0
