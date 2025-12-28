#!/usr/bin/env bash
# Robust script to rerun a GitHub Actions run and fetch its logs.
# Usage: ./scripts/rerun_and_fetch.sh <original_run_id>
# Requires: GITHUB_TOKEN env var with repo/workflow scopes, and `jq` installed.

set -u
SCRIPT_NAME=$(basename "$0")
ROOT_API="https://api.github.com/repos/hfcs/simple_match"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: 'jq' is required. Install it (brew install jq) and retry." >&2
  exit 2
fi

if [ -z "${GITHUB_TOKEN-}" ]; then
  echo "ERROR: GITHUB_TOKEN environment variable is not set." >&2
  exit 2
fi

if [ "$#" -lt 1 ]; then
  echo "Usage: $SCRIPT_NAME <original_run_id> [poll_interval_seconds] [max_attempts]" >&2
  exit 2
fi

ORIG_RUN_ID="$1"
POLL_INTERVAL_SECONDS=${2-15}
MAX_ATTEMPTS=${3-80}

echo "Rerun helper starting for run id: $ORIG_RUN_ID"

# Helper: http GET returning JSON to file
http_get_json() {
  # GET JSON and return HTTP status code; write body to $2
  local url="$1" out="$2"
  http_status=$(curl -sS -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$url" -o "$out" 2>/dev/null)
  echo "$http_status"
}

# 1) Fetch original run details
ORIG_JSON=/tmp/orig_run_${ORIG_RUN_ID}.json
http_get_json "$ROOT_API/actions/runs/${ORIG_RUN_ID}" "$ORIG_JSON"
if [ ! -s "$ORIG_JSON" ]; then
  echo "Failed to fetch original run details. Check run id and token." >&2
  exit 3
fi
ORIG_HEAD_SHA=$(jq -r '.head_sha // empty' "$ORIG_JSON")
ORIG_CREATED_AT=$(jq -r '.created_at // empty' "$ORIG_JSON")
ORIG_WORKFLOW=$(jq -r '.name // empty' "$ORIG_JSON")
ORIG_RUN_ATTEMPT=$(jq -r '.run_attempt // 0' "$ORIG_JSON" 2>/dev/null || echo 0)

if [ -z "$ORIG_HEAD_SHA" ]; then
  echo "Warning: couldn't determine head_sha for original run; rerun-match will use created_at detection." >&2
fi

echo "Original run: head_sha=$ORIG_HEAD_SHA created_at=$ORIG_CREATED_AT workflow=$ORIG_WORKFLOW"

# 2) POST rerun
echo "Requesting rerun..."
RERUN_RESP=/tmp/rerun_resp_${ORIG_RUN_ID}.json
HTTP_CODE=$(curl -s -o "$RERUN_RESP" -w "%{http_code}" -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "$ROOT_API/actions/runs/${ORIG_RUN_ID}/rerun")

if [ "$HTTP_CODE" != "201" ] && [ "$HTTP_CODE" != "202" ]; then
  echo "Rerun request returned HTTP $HTTP_CODE" >&2
  cat "$RERUN_RESP" 2>/dev/null || true
  # continue — sometimes GitHub returns 202 Accepted with no body; treat as OK
fi

echo "Rerun requested (response code $HTTP_CODE). Polling for the new run..."

# 3) Poll for the new run that matches head_sha and is newer than orig_created_at.
NEW_RUN_ID=""
attempt=0
while [ $attempt -lt $MAX_ATTEMPTS ]; do
  attempt=$((attempt+1))
  echo "Polling attempt $attempt/$MAX_ATTEMPTS..."
  RECENT_JSON=/tmp/recent_runs_poll.json
  http_get_json "$ROOT_API/actions/runs?per_page=50" "$RECENT_JSON"
  if [ ! -s "$RECENT_JSON" ]; then
    echo "Failed to list runs; retrying in ${POLL_INTERVAL_SECONDS}s..."
    sleep $POLL_INTERVAL_SECONDS
    continue
  fi

  # Try to find a run with the same head_sha that has created_at > orig_created_at
  if [ -n "$ORIG_HEAD_SHA" ]; then
    NEW_RUN_ID=$(jq -r --arg sha "$ORIG_HEAD_SHA" --arg ca "$ORIG_CREATED_AT" '.workflow_runs[] | select(.head_sha == $sha and (.created_at // "") > $ca) | .id' "$RECENT_JSON" | head -n1 || true)
  fi

  # fallback: find a run for the same workflow name created after the original
  if [ -z "$NEW_RUN_ID" ] && [ -n "$ORIG_CREATED_AT" ] && [ -n "$ORIG_WORKFLOW" ]; then
    NEW_RUN_ID=$(jq -r --arg wf "$ORIG_WORKFLOW" --arg ca "$ORIG_CREATED_AT" '.workflow_runs[] | select((.name == $wf) and (.created_at // "") > $ca) | .id' "$RECENT_JSON" | head -n1 || true)
  fi

  if [ -n "$NEW_RUN_ID" ]; then
    echo "Found candidate new run id: $NEW_RUN_ID"
    break
  fi
  sleep $POLL_INTERVAL_SECONDS
done

if [ -z "$NEW_RUN_ID" ]; then
  # It's possible GitHub created a new attempt for the same run id (rerun uses same run id).
  echo "No new run id found; checking if original run got a new attempt (same run id)."
  # fetch latest run JSON and compare run_attempt
  LATEST_ORIG_JSON=/tmp/orig_run_latest_${ORIG_RUN_ID}.json
  attempt_attempt=0
  while [ $attempt_attempt -lt $MAX_ATTEMPTS ]; do
    http_get_json "$ROOT_API/actions/runs/${ORIG_RUN_ID}" "$LATEST_ORIG_JSON"
    latest_attempt=$(jq -r '.run_attempt // 0' "$LATEST_ORIG_JSON" 2>/dev/null || echo 0)
    echo "check attempt #$attempt_attempt: run_attempt=$latest_attempt (orig was ${ORIG_RUN_ATTEMPT-0})"
    if [ "$latest_attempt" -gt "${ORIG_RUN_ATTEMPT-0}" ]; then
      echo "Detected new attempt ($latest_attempt) for run ${ORIG_RUN_ID}";
      NEW_RUN_ID="$ORIG_RUN_ID"
      break
    fi
    attempt_attempt=$((attempt_attempt+1))
    sleep $POLL_INTERVAL_SECONDS
  done
fi

if [ -z "$NEW_RUN_ID" ]; then
  echo "Timed out waiting for new run to appear after rerun request." >&2
  exit 4
fi

echo "Polling run $NEW_RUN_ID until run attempt/status indicate completion..."
# 4) Prefer polling the run JSON itself for run_attempt and status; jobs endpoint is secondary
NEW_JSON=/tmp/new_run_${NEW_RUN_ID}.json
attempt=0
while [ $attempt -lt $MAX_ATTEMPTS ]; do
  attempt=$((attempt+1))
  status_code=$(http_get_json "$ROOT_API/actions/runs/${NEW_RUN_ID}" "$NEW_JSON")
  if [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
    cur_attempt=$(jq -r '.run_attempt // 0' "$NEW_JSON" 2>/dev/null || echo 0)
    status=$(jq -r '.status // empty' "$NEW_JSON" 2>/dev/null || echo "")
    conclusion=$(jq -r '.conclusion // empty' "$NEW_JSON" 2>/dev/null || echo "")
    echo "Attempt $attempt: HTTP $status_code run_attempt=$cur_attempt status=$status conclusion=$conclusion"

    # If this is the same run id as original, require attempt increase (rerun creates new attempt)
    if [ "$NEW_RUN_ID" = "$ORIG_RUN_ID" ]; then
      if [ "$cur_attempt" -le "$ORIG_RUN_ATTEMPT" ]; then
        echo "Run attempt ($cur_attempt) not greater than original ($ORIG_RUN_ATTEMPT); waiting..."
        sleep $POLL_INTERVAL_SECONDS && continue
      fi
    fi

    # If run status is completed, we're done (capture conclusion)
    if [ "$status" = "completed" ]; then
      echo "Run reached completed with conclusion=$conclusion"
      break
    fi
  else
    echo "Attempt $attempt: HTTP $status_code fetching run JSON; retrying"
  fi
  sleep $POLL_INTERVAL_SECONDS
done

if [ ! -s "$NEW_JSON" ]; then
  echo "Failed to fetch new run JSON." >&2
  exit 5
fi

status=$(jq -r '.status // empty' "$NEW_JSON")
conclusion=$(jq -r '.conclusion // empty' "$NEW_JSON")
echo "Run final status=$status conclusion=$conclusion"
if [ "$status" != "completed" ]; then
  echo "Run did not reach completed status (status=$status)." >&2
fi

LOGS_URL=$(jq -r '.logs_url // empty' "$NEW_JSON")
if [ -z "$LOGS_URL" ]; then
  echo "No logs_url found for run $NEW_RUN_ID" >&2
  exit 6
fi

# 5) Download logs ZIP and extract
ZIP=/tmp/run-${NEW_RUN_ID}-logs.zip
DEST=/tmp/actions_run_${NEW_RUN_ID}_logs
echo "Downloading logs from: $LOGS_URL to $ZIP"
curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/zip" -L "$LOGS_URL" -o "$ZIP" || { echo "Download failed" >&2; exit 7; }

rm -rf "$DEST"
mkdir -p "$DEST"
unzip -oq "$ZIP" -d "$DEST" || { echo "Failed to unzip logs" >&2; exit 8; }

echo "Logs extracted to: $DEST"

# 6) Print a summary of jobs
JOBS_JSON=/tmp/run_${NEW_RUN_ID}_jobs.json
http_get_json "$ROOT_API/actions/runs/${NEW_RUN_ID}/jobs" "$JOBS_JSON"
if [ -s "$JOBS_JSON" ]; then
  echo "\nJob summary:"
  jq -r '.jobs[] | "- id="+.id|tostring+" name="+.name+" status="+.status+" conclusion="+.conclusion' "$JOBS_JSON" 2>/dev/null || jq -r '.jobs[] | {id: .id, name: .name, status: .status, conclusion: .conclusion}' "$JOBS_JSON"
else
  echo "No jobs JSON available." >&2
fi

echo "Script completed. Logs directory: $DEST"
exit 0
