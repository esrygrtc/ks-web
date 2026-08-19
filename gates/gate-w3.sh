#!/bin/bash
# HYPOTHESIS: a stranger can navigate from landing to a runnable
# quickstart. Zero broken links; search returns the quickstart for
# "resume"; every code block has a working copy button (tested in a real
# browser); synced content is hash-checked against its sources.
#
# Sabotage (--sabotage): corrupt the quickstart sync hash in
# src/generated/docs.json; the hash check, and therefore the gate, must
# fail. GREEN iff it does.
#
# WORLD 1 (macOS): portable clock. Hard cap 900 s. Assumes committed tree.
set -u
cd "$(dirname "$0")/.."
MODE="${1:-normal}"
FAILS=0
pass() { echo "ASSERT PASS: $*"; }
fail() { echo "ASSERT FAIL: $*"; FAILS=$((FAILS+1)); }
cleanup() {
  git checkout -q -- src/generated/docs.json 2>/dev/null || true
  pkill -f 'astro preview' 2>/dev/null || true
}
trap cleanup EXIT

echo "=== GATE W3 ($MODE mode) $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="

if [ "$MODE" = "--sabotage" ]; then
  echo "--- sabotage: a corrupted sync hash must fail the check ---"
  python3 - <<'PY'
import json
p = 'src/generated/docs.json'
d = json.load(open(p))
d['sourceSha'] = '0' * 64
json.dump(d, open(p, 'w'), indent=2)
PY
  if node scripts/check-sync-docs.mjs >/dev/null 2>&1; then
    fail "hash check passed over a corrupted sourceSha"
  else
    pass "hash check fails on the corrupted quickstart sync hash"
  fi
  git checkout -q -- src/generated/docs.json
  node scripts/check-sync-docs.mjs >/dev/null 2>&1 && pass "restored; hash check green again" || fail "hash check still red after restore"
  if [ "$FAILS" -eq 0 ]; then echo "GATE W3 SABOTAGE: GREEN - corrupted sync cannot pass"; exit 0; fi
  echo "GATE W3 SABOTAGE: RED - $FAILS assertion(s) failed"; exit 1
fi

echo "--- 1. synced content is fresh against its sources ---"
node scripts/check-sync.mjs >/dev/null 2>&1 && pass "claims sync fresh" || fail "claims sync stale/hand-edited"
node scripts/check-sync-docs.mjs >/dev/null 2>&1 && pass "docs sync fresh (quickstart, limits, CLI, API, changelog)" || fail "docs sync stale/hand-edited"

echo "--- 2. build + full link lint ---"
npm run build >/tmp/w3-build.log 2>&1 && pass "site builds with search index" || { fail "build failed"; tail -5 /tmp/w3-build.log; }
node scripts/lint-links.mjs && pass "link lint green" || fail "link lint red"
node scripts/lint-emdash.mjs >/dev/null 2>&1 && pass "em-dash lint green" || fail "em-dash lint red"
node scripts/lint-copy.mjs >/dev/null 2>&1 && pass "copy fidelity green" || fail "copy fidelity red"

echo "--- 3. the stranger's path exists in the built HTML ---"
grep -q 'href="/docs' dist/index.html && pass "landing links to docs" || fail "no docs link on landing"
grep -q 'QUICKSTART-RESUME-OK' dist/docs/quickstart/index.html && pass "quickstart carries the gate-tested success marker" || fail "quickstart missing its success marker text"
N=$(grep -o '<pre' dist/docs/quickstart/index.html | wc -l | tr -d ' ')
B=$(grep -o 'class="ks-copy"' dist/docs/quickstart/index.html | wc -l | tr -d ' ')
[ "$N" -ge 4 ] && [ "$N" = "$B" ] && pass "static check: $B copy buttons on $N code blocks" || fail "copy buttons $B != code blocks $N (or too few blocks)"

echo "--- 4. browser leg: search + live copy ---"
(npx astro preview --port 4321 >/tmp/w3-preview.log 2>&1 &)
sleep 4
node gates/gate-w3-browser.mjs || FAILS=$((FAILS+1))
pkill -f 'astro preview' 2>/dev/null || true

echo "--- 5. the Ledger draft is marked ---"
if [ -f dist/ledger/index.html ]; then
  grep -qi 'draft' dist/ledger/index.html && pass "draft post visibly marked on the Ledger index" || fail "draft not marked"
else
  fail "ledger index missing"
fi

if [ "$FAILS" -eq 0 ]; then echo "GATE W3: GREEN - landing to runnable quickstart, no dead ends"; exit 0; fi
echo "GATE W3: RED - $FAILS assertion(s) failed"; exit 1
