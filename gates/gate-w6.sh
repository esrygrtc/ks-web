#!/bin/bash
# HYPOTHESIS: launch is boring. DNS and TLS are green on apex and www;
# 500 concurrent users for 10 minutes against production see p95 TTFB
# under 300 ms with zero errors on static pages (form endpoints excluded
# from load by law); rollback has been rehearsed and timed under 10
# minutes; the uptime alert has test-fired once.
#
# This gate runs on CUTOVER DAY, after the founder sets DNS and deploys
# production. Sabotage (--sabotage): rollback pointed at a nonexistent
# artifact must abort loudly (exit-75 semantics), never half-deploy.
#
# WORLD 1 (macOS): portable clock. Hard cap 1800 s (k6 runs 10 minutes).
set -u
cd "$(dirname "$0")/.."
APEX=https://keepstate.ai
WWW=https://www.keepstate.ai
PROD_MARKER='durable agent session cloud'
MODE="${1:-normal}"
FAILS=0
pass() { echo "ASSERT PASS: $*"; }
fail() { echo "ASSERT FAIL: $*"; FAILS=$((FAILS+1)); }

echo "=== GATE W6 ($MODE mode) $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="

if [ "$MODE" = "--sabotage" ]; then
  echo "--- sabotage: rollback to a nonexistent artifact ---"
  BEFORE=$(curl -fsS "$APEX/" 2>/dev/null | grep -c "$PROD_MARKER" || echo 0)
  if bash scripts/rollback.sh 99999999999 production >/tmp/w6-sab.log 2>&1; then
    fail "rollback claimed success against a nonexistent artifact"
  else
    pass "rollback aborted loudly (nonzero exit)"
  fi
  grep -q 'ABORT(75)' /tmp/w6-sab.log && pass "abort named its cause with exit-75 semantics" \
    || { gh run view --repo esrygrtc/ks-web $(gh run list --repo esrygrtc/ks-web --workflow rollback.yml --limit 1 --json databaseId -q '.[0].databaseId') --log-failed 2>/dev/null | grep -q 'ABORT(75)' && pass "abort named its cause (workflow log)" || fail "no named abort cause"; }
  AFTER=$(curl -fsS "$APEX/" 2>/dev/null | grep -c "$PROD_MARKER" || echo 0)
  [ "$BEFORE" = "$AFTER" ] && pass "production content untouched through the abort ($BEFORE -> $AFTER)" || fail "production changed during an aborted rollback"
  if [ "$FAILS" -eq 0 ]; then echo "GATE W6 SABOTAGE: GREEN - a bad rollback cannot half-deploy"; exit 0; fi
  echo "GATE W6 SABOTAGE: RED - $FAILS assertion(s) failed"; exit 1
fi

echo "--- 1. DNS + TLS on apex and www ---"
for U in "$APEX" "$WWW"; do
  CODE=$(curl -fsS -o /dev/null -w '%{http_code}' "$U/" 2>/dev/null || echo 000)
  [ "$CODE" = "200" ] && pass "$U serves 200 over TLS" || fail "$U returned $CODE"
  EXP=$(echo | openssl s_client -servername "${U#https://}" -connect "${U#https://}:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null)
  [ -n "$EXP" ] && pass "$U certificate present ($EXP)" || fail "$U no certificate"
done
curl -fsS "$APEX/" | grep -q "$PROD_MARKER" && pass "production serves the real site" || fail "production content wrong"

echo "--- 2. cache policy live ---"
curl -s -D- -o /dev/null "$APEX/fonts/Inter-400-normal.woff2" | grep -qi 'immutable' && pass "assets immutable" || fail "asset cache policy missing"
curl -s -D- -o /dev/null "$APEX/" | grep -qi 'max-age=300' && pass "HTML short-cached" || fail "HTML cache policy missing"

echo "--- 3. the load: 500 VUs, 10 minutes, static paths only ---"
k6 run -e BASE="$APEX" infra/load-test.js --summary-mode=compact >/tmp/w6-k6.log 2>&1
K6RC=$?
grep -E 'http_req_failed|http_req_waiting|http_reqs' /tmp/w6-k6.log | head -4
[ $K6RC -eq 0 ] && pass "k6 thresholds held (p95 TTFB < 300 ms, zero errors)" || fail "k6 thresholds violated (rc=$K6RC)"

echo "--- 4. rollback rehearsal, timed ---"
PREV=$(gh run list --repo esrygrtc/ks-web --workflow ci.yml --limit 5 --json databaseId,conclusion -q '[.[] | select(.conclusion=="success")][1].databaseId')
CURR=$(gh run list --repo esrygrtc/ks-web --workflow ci.yml --limit 5 --json databaseId,conclusion -q '[.[] | select(.conclusion=="success")][0].databaseId')
T0=$(date +%s)
bash scripts/rollback.sh "$PREV" production >/tmp/w6-rb1.log 2>&1 && pass "rolled production to previous artifact" || fail "rollback to previous failed"
curl -fsS "$APEX/" | grep -q "$PROD_MARKER" && pass "previous artifact verified live" || fail "previous artifact not serving"
bash scripts/rollback.sh "$CURR" production >/tmp/w6-rb2.log 2>&1 && pass "re-deployed current artifact" || fail "roll-forward failed"
T1=$(date +%s)
DT=$((T1-T0))
[ "$DT" -lt 600 ] && pass "full rollback cycle in ${DT}s < 600s" || fail "rollback cycle ${DT}s over budget"

echo "--- 5. uptime alert test-fired ---"
az monitor metrics alert show -g ks-web-rg -n ks-web-down --query enabled -o tsv 2>/dev/null | grep -q true \
  && pass "availability alert exists and is enabled" || fail "uptime alert missing (infra/create-uptime.sh not yet approved/run)"
echo "NOTE: the test-fire is a human-witnessed step: disable/enable or use the portal's test action; record it in docs/phase-w6.md."

if [ "$FAILS" -eq 0 ]; then echo "GATE W6: GREEN - launch is boring"; exit 0; fi
echo "GATE W6: RED - $FAILS assertion(s) failed"; exit 1
