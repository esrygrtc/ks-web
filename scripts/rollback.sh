#!/bin/bash
# scripts/rollback.sh <run_id> [staging|production]
# Triggers the rollback workflow and watches it to conclusion. Timed:
# the W6 gate requires the full cycle under 10 minutes.
set -euo pipefail
RUN_ID="${1:?usage: rollback.sh <run_id> [staging|production]}"
ENV="${2:-staging}"
T0=$(date +%s)
gh workflow run rollback.yml --repo esrygrtc/ks-web -f run_id="$RUN_ID" -f environment="$ENV"
sleep 8
WATCH=$(gh run list --repo esrygrtc/ks-web --workflow rollback.yml --limit 1 --json databaseId -q '.[0].databaseId')
echo "rollback run $WATCH (artifact from $RUN_ID -> $ENV)"
while :; do
  C=$(gh run list --repo esrygrtc/ks-web --workflow rollback.yml --limit 1 --json conclusion -q '.[0].conclusion')
  [ -n "$C" ] && break
  sleep 10
done
T1=$(date +%s)
echo "conclusion: $C in $((T1-T0))s"
[ "$C" = "success" ]
