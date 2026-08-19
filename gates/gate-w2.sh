#!/bin/bash
# HYPOTHESIS: the public site matches its spec and its laws. All four
# house lints are green (em-dash, evidence, links, copy fidelity), the
# sync-claims hash check is green, the footer renders the status feed
# unavailable-by-honesty, and sitemap, OG image, and robots.txt exist
# and are sane.
#
# Sabotage (--sabotage): an em dash planted in a copy fixture and an
# evidence-free row planted in proof.json. GREEN iff the em-dash lint,
# the evidence lint, AND the hash check all fail on their sabotage.
#
# WORLD 1 (macOS): portable clock. Hard cap 900 s. Assumes a committed
# tree (restores fixtures via git checkout).
set -u
cd "$(dirname "$0")/.."
MODE="${1:-normal}"
FAILS=0
pass() { echo "ASSERT PASS: $*"; }
fail() { echo "ASSERT FAIL: $*"; FAILS=$((FAILS+1)); }
cleanup() {
  git checkout -q -- src/generated/proof.json 2>/dev/null || true
  rm -f design/copy/__sabotage__.txt
}
trap cleanup EXIT

echo "=== GATE W2 ($MODE mode) $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="

if [ "$MODE" = "--sabotage" ]; then
  echo "--- sabotage 1: an em dash in content must fail the em-dash lint ---"
  printf 'This sentence has an em dash \xe2\x80\x94 planted by the gate.\n' > design/copy/__sabotage__.txt
  if node scripts/lint-emdash.mjs >/dev/null 2>&1; then
    fail "em-dash lint passed over a planted em dash"
  else
    pass "em-dash lint fails on the planted em dash"
  fi
  rm -f design/copy/__sabotage__.txt

  echo "--- sabotage 2: an evidence-free claim row must fail the evidence lint AND the hash check ---"
  python3 - <<'PY'
import json
p = 'src/generated/proof.json'
d = json.load(open(p))
d['proven'].append({'claim': 'Planted claim with no evidence', 'provenBy': 'nothing', 'evidence': 'trust us'})
json.dump(d, open(p, 'w'), indent=2)
PY
  if node scripts/lint-evidence.mjs >/dev/null 2>&1; then
    fail "evidence lint passed over an evidence-free row"
  else
    pass "evidence lint fails on the evidence-free row"
  fi
  if node scripts/check-sync.mjs >/dev/null 2>&1; then
    fail "hash check passed over a hand-edited proof.json"
  else
    pass "hash check fails on the hand edit (UI Law 4 bites)"
  fi
  git checkout -q -- src/generated/proof.json
  node scripts/lint-evidence.mjs >/dev/null 2>&1 && pass "restored; evidence lint green again" || fail "evidence lint still red after restore"
  if [ "$FAILS" -eq 0 ]; then echo "GATE W2 SABOTAGE: GREEN - the lints bite"; exit 0; fi
  echo "GATE W2 SABOTAGE: RED - $FAILS assertion(s) failed"; exit 1
fi

echo "--- 1. sync freshness and the four lints ---"
node scripts/check-sync.mjs && pass "sync-claims hash check green" || fail "proof.json stale or hand-edited"
node scripts/lint-emdash.mjs >/dev/null 2>&1 && pass "em-dash lint green" || fail "em-dash lint red"
node scripts/lint-evidence.mjs >/dev/null 2>&1 && pass "evidence lint green" || fail "evidence lint red"

echo "--- 2. build, then post-build lints ---"
npm run build >/tmp/w2-build.log 2>&1 && pass "site builds" || { fail "build failed"; tail -5 /tmp/w2-build.log; }
node scripts/lint-links.mjs && pass "link lint green (no broken links, no orphans)" || fail "link lint red"
node scripts/lint-copy.mjs && pass "copy fidelity green" || fail "copy fidelity red"

echo "--- 3. the footer is honest ---"
HOME=dist/index.html
if [ -f "$HOME" ]; then
  grep -q 'data-status="unavailable"' "$HOME" && pass "footer status chip renders unavailable with no feed" || fail "footer chip not unavailable"
  grep -q 'api unavailable' "$HOME" && pass "system line prints unavailable per field, never zero" || fail "system line missing honest unavailable fields"
  grep -q 'data-status="operational"' "$HOME" && fail "footer claims operational with no feed" || pass "no fake green anywhere in the footer"
else
  fail "dist/index.html missing"
fi

echo "--- 4. sitemap, OG, robots ---"
ls dist/sitemap-*.xml >/dev/null 2>&1 && pass "sitemap generated" || fail "sitemap missing"
grep -q 'design-system' dist/sitemap-0.xml 2>/dev/null && fail "sitemap leaks /design-system" || pass "sitemap excludes internal tooling"
[ -f dist/og.png ] && [ "$(stat -f%z dist/og.png)" -gt 10000 ] && pass "OG image present and non-trivial" || fail "og.png missing or tiny"
grep -q 'Sitemap: https://keepstate.ai' dist/robots.txt 2>/dev/null && pass "robots.txt sane, cites the sitemap" || fail "robots.txt broken"
PAGES=$(find dist -name index.html | wc -l | tr -d ' ')
[ "$PAGES" -ge 18 ] && pass "page inventory: $PAGES pages built" || fail "only $PAGES pages built; W2 expects 18+"

if [ "$FAILS" -eq 0 ]; then echo "GATE W2: GREEN - the public site matches its spec and its laws"; exit 0; fi
echo "GATE W2: RED - $FAILS assertion(s) failed"; exit 1
