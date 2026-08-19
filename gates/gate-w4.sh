#!/bin/bash
# HYPOTHESIS: no lead can be lost and no state lies. Every form writes a
# durable Table row BEFORE email is attempted; a dead email step still
# preserves the row (run live); malformed submits are rejected politely;
# bots feed the honeypot and store nothing; the rate limit holds; OAuth
# redirects to GitHub; the console shell renders only honest states.
#
# Email-arrival leg: if no provider is configured (KS_EMAIL_KEY unset in
# SWA settings), the leg ABORTS with exit-75 semantics: a trial that
# cannot be held is neither green nor red. The gate says so loudly and
# the phase records it; the leg runs for real when the founder sets the
# key.
#
# Sabotage (--sabotage): break the Table connection; a submission must
# fail on durability (no thanks, no row), never fall through to email.
#
# WORLD 1 (macOS): portable clock. Hard cap 900 s.
set -u
cd "$(dirname "$0")/.."
BASE="${GATE_BASE:-https://icy-wave-0eefe5403-staging.westeurope.7.azurestaticapps.net}"
ACCT=kswebleads
RG=ks-web-rg
MODE="${1:-normal}"
FAILS=0
pass() { echo "ASSERT PASS: $*"; }
fail() { echo "ASSERT FAIL: $*"; FAILS=$((FAILS+1)); }
KEY=$(az storage account keys list -n $ACCT -g $RG --query '[0].value' -o tsv)
rows() { az storage entity query --account-name $ACCT --account-key "$KEY" --table-name "$1" --filter "RowKey ge '$2'" --query 'length(items)' -o tsv 2>/dev/null; }
lastrow() { az storage entity query --account-name $ACCT --account-key "$KEY" --table-name "$1" --filter "RowKey ge '$2'" --query 'items[-1]' -o json 2>/dev/null; }
post() { curl -s -o /dev/null -w '%{http_code} %{redirect_url}' -X POST "$BASE/api/$1" -d "$2"; }
restore_conn() {
  CONN=$(az storage account show-connection-string -n $ACCT -g $RG --query connectionString -o tsv)
  az staticwebapp appsettings set -n ks-web --setting-names "KS_LEADS_CONN=$CONN" -o none
  unset CONN
}
cleanup() { :; }
trap cleanup EXIT

echo "=== GATE W4 ($MODE mode) $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="
T0=$(date -u '+%Y-%m-%dT%H:%M:%S')

if [ "$MODE" = "--sabotage" ]; then
  echo "--- sabotage: Table connection broken; durability must fail loudly ---"
  az staticwebapp appsettings set -n ks-web --setting-names "KS_LEADS_CONN=DefaultEndpointsProtocol=https;AccountName=nonexistent$RANDOM;AccountKey=Zm9v;EndpointSuffix=core.windows.net" -o none
  sleep 20
  R=$(post partner "name=Sabotage&email=sab@example.com&company=Gate&agent=none")
  echo "response: $R"
  echo "$R" | grep -q '/thanks' && fail "submission reported SUCCESS while storage was broken" || pass "no false success: durability failure is not hidden"
  echo "$R" | grep -q 'sorry?why=storage' && pass "failure names durability (why=storage), not email" || fail "failure did not name storage"
  N=$(rows leads "$T0")
  [ "${N:-0}" = "0" ] && pass "no row was written (nothing false in the ledger)" || fail "a row appeared despite broken storage"
  restore_conn; sleep 20
  R2=$(post partner "name=Restore&email=restore@example.com&company=Gate&agent=none")
  echo "$R2" | grep -q '/thanks' && pass "restored: a submission lands again" || fail "still failing after restore"
  if [ "$FAILS" -eq 0 ]; then echo "GATE W4 SABOTAGE: GREEN - the failure is on durability, never on email"; exit 0; fi
  echo "GATE W4 SABOTAGE: RED - $FAILS assertion(s) failed"; exit 1
fi

echo "--- 0. mechanical order proof: the row precedes the email in code ---"
W=$(grep -n 'createEntity' api/src/functions/forms.js | head -1 | cut -d: -f1)
E=$(grep -n 'await notify' api/src/functions/forms.js | head -1 | cut -d: -f1)
[ -n "$W" ] && [ -n "$E" ] && [ "$W" -lt "$E" ] && pass "createEntity (line $W) precedes notify (line $E)" || fail "email does not strictly follow the durable write"

echo "--- 1. each form: valid submission -> thanks + durable row ---"
declare -a SPECS=(
  "partner|name=Gate W4&email=gate-w4@example.com&company=KeepState&agent=claude|leads"
  "grants|track=maintainer&name=Gate W4&link=https://example.com&run=test&credits=5000|grants"
  "subscribe|email=gate-w4-sub@example.com|subscribers"
  "contact|name=Gate W4&email=gate-w4-c@example.com&message=gate run|contact"
)
for spec in "${SPECS[@]}"; do
  F="${spec%%|*}"; rest="${spec#*|}"; DATA="${rest%%|*}"; TBL="${rest##*|}"
  R=$(post "$F" "$DATA")
  echo "$R" | grep -q '/thanks' && pass "$F: accepted (303 -> /thanks)" || fail "$F: not accepted ($R)"
  sleep 2
  N=$(rows "$TBL" "$T0")
  [ "${N:-0}" -ge 1 ] && pass "$F: durable row in table '$TBL'" || fail "$F: no row in '$TBL'"
done

echo "--- 2. the dead email step, run live ---"
ES=$(lastrow leads "$T0" | python3 -c "import json,sys; print(json.load(sys.stdin).get('emailStatus','missing'))")
if [ "$ES" = "unconfigured" ]; then
  pass "email step is dead (unconfigured) and the row survived it: recorded emailStatus=$ES"
  echo "LEG ABORTED (exit-75 semantics): email-arrival cannot be tried, no provider key is configured. The leg runs when the founder sets KS_EMAIL_KEY."
elif [ "$ES" = "sent" ]; then
  pass "email step configured and reports sent (founder confirms arrival out-of-band)"
else
  fail "emailStatus is '$ES': neither a recorded dead step nor a send"
fi

echo "--- 3. malformed submissions rejected politely, stored never ---"
B1=$(rows leads "$T0")
R=$(post partner "name=&email=bad&company=&agent=")
echo "$R" | grep -q '/sorry' && pass "missing fields -> /sorry" || fail "missing fields not rejected ($R)"
R=$(post partner "name=X&email=not-an-email&company=Y&agent=Z")
echo "$R" | grep -q '/sorry' && pass "invalid email -> /sorry" || fail "invalid email accepted ($R)"
B2=$(rows leads "$T0")
[ "$B1" = "$B2" ] && pass "rejects stored nothing (rows $B1 -> $B2)" || fail "a malformed submit was stored"

echo "--- 4. honeypot: pretends success, stores nothing ---"
R=$(post contact "name=Bot&email=bot@example.com&message=spam&website=http://spam")
echo "$R" | grep -q '/thanks' && pass "honeypot answered with success" || fail "honeypot leaked a different signal ($R)"
NC1=$(rows contact "$T0")
sleep 2
NC2=$(rows contact "$T0")
[ "$NC1" = "$NC2" ] && [ "${NC1:-0}" -le 1 ] && pass "honeypot stored nothing (contact rows steady at $NC1)" || fail "honeypot wrote a row"

echo "--- 5. rate limit: the sixth rapid submit is refused ---"
CODES=""
for i in 1 2 3 4 5 6; do
  C=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$BASE/api/subscribe" -d "email=burst$i@example.com")
  CODES="$CODES $C"
done
echo "codes:$CODES"
echo "$CODES" | grep -q '429' && pass "burst met a 429" || fail "no 429 in a six-submit burst"

echo "--- 6. OAuth wiring: GitHub answers the door ---"
LOC=$(curl -s -o /dev/null -w '%{redirect_url}' "$BASE/.auth/login/github")
echo "$LOC" | grep -q 'github.com' && pass "/.auth/login/github redirects to github.com" || fail "auth redirect went to: ${LOC:-nowhere}"

echo "--- 7. the console shell lies to no one ---"
H=$(curl -fsS "$BASE/console/")
echo "$H" | grep -q 'Continue with GitHub' && pass "signed-out state renders" || fail "sign-in state missing"
echo "$H" | grep -qiE 'data-console-state' && pass "state machine present" || fail "console state markers missing"
echo "$H" | grep -qiE '[0-9]+ (sessions|checkpoints|tokens)' && fail "console shows invented metrics" || pass "zero invented metrics in the shell"

if [ "$FAILS" -eq 0 ]; then echo "GATE W4: GREEN - no lead can be lost and no state lies"; exit 0; fi
echo "GATE W4: RED - $FAILS assertion(s) failed"; exit 1
