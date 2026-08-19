#!/bin/bash
# HYPOTHESIS: the design system enforces its own laws. A null-fed metric
# card renders "unavailable" and cannot render 0; a status chip without a
# feed cannot be green; numbers without provenance refuse to render; and
# every state, unavailable states included, is visible on /design-system.
#
# Sabotage mode (--sabotage): disable MetricCard's Law-1 guard (the
# LAW1_GUARD line) and re-run the tests. GREEN iff the tests FAIL, which
# proves they test the law and not the weather.
#
# WORLD 1 (macOS): portable clock. Hard cap 900 s.
set -u
cd "$(dirname "$0")/.."
START=$(date +%s)
MODE="${1:-normal}"
FAILS=0
pass() { echo "ASSERT PASS: $*"; }
fail() { echo "ASSERT FAIL: $*"; FAILS=$((FAILS+1)); }
cleanup() { git checkout -q -- src/components/MetricCard.astro 2>/dev/null || true; rm -f /tmp/w1-vitest.json; }
trap cleanup EXIT

echo "=== GATE W1 ($MODE mode) $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="

if [ "$MODE" = "--sabotage" ]; then
  echo "--- sabotage: Law-1 guard disabled; the tests must catch it ---"
  grep -q 'LAW1_GUARD' src/components/MetricCard.astro || { echo "GATE W1 SABOTAGE: ABORT - guard marker missing (exit 75)"; exit 75; }
  sed -i '' 's/^const missing = .*LAW1_GUARD$/const missing = false; \/\/ LAW1_GUARD sabotaged/' src/components/MetricCard.astro
  grep -q 'sabotaged' src/components/MetricCard.astro || { echo "GATE W1 SABOTAGE: ABORT - patch did not apply (exit 75)"; exit 75; }
  if npx vitest run >/tmp/w1-sab.log 2>&1; then
    fail "tests PASSED with the Law-1 guard disabled - they test nothing"
  else
    pass "tests fail when the guard is disabled"
    grep -qE 'cannot render 0.*(FAIL|✗|×)|(FAIL|✗|×).*cannot render 0' /tmp/w1-sab.log \
      && pass "the failing test is the null-cannot-render-0 law itself" \
      || { grep -q 'cannot render 0' /tmp/w1-sab.log && pass "null-cannot-render-0 present in failure output" || fail "failure output does not implicate the Law-1 tests"; }
  fi
  git checkout -q -- src/components/MetricCard.astro
  npx vitest run >/dev/null 2>&1 && pass "guard restored; tests green again" || fail "tests still red after restore"
  if [ "$FAILS" -eq 0 ]; then echo "GATE W1 SABOTAGE: GREEN - the law tests bite"; exit 0; fi
  echo "GATE W1 SABOTAGE: RED - $FAILS assertion(s) failed"; exit 1
fi

echo "--- 1. the law tests exist, by name, and pass (rule 13: names, not counts) ---"
npx vitest run --reporter=json >/tmp/w1-vitest.json 2>/dev/null
RC=$?
python3 - "$RC" <<'PY'
import json, sys
rc = int(sys.argv[1])
d = json.load(open('/tmp/w1-vitest.json'))
names = []
for tf in d.get('testResults', []):
    for a in tf.get('assertionResults', []):
        names.append((a['title'], a['status']))
required = [
  'metric card with null data renders unavailable',
  'metric card with null data cannot render 0',
  'status chip without feed renders UNAVAILABLE',
  'green is impossible without live data',
  'metric card without badge or evidence link refuses to render',
  'a measured zero renders 0: a zero is a measurement',
  'a preserved artifact renders no delete affordance at all',
]
ok = True
if not names:
    print('ASSERT FAIL: no test results parsed - refusing to pass on empty evidence'); ok = False
for r in required:
    hit = [s for t, s in names if r in t]
    if not hit: print(f'ASSERT FAIL: required law test missing: "{r}"'); ok = False
    elif hit[0] != 'passed': print(f'ASSERT FAIL: law test not passing: "{r}" ({hit[0]})'); ok = False
    else: print(f'ASSERT PASS: law test green: "{r}"')
if rc != 0:
    print(f'ASSERT FAIL: vitest exit {rc}'); ok = False
else:
    print(f'ASSERT PASS: full suite green ({len(names)} tests)')
sys.exit(0 if ok else 1)
PY
[ $? -eq 0 ] || FAILS=$((FAILS+1))

echo "--- 2. /design-system renders every unavailable state ---"
npm run build >/tmp/w1-build.log 2>&1 || { fail "build failed"; }
PAGE=dist/design-system/index.html
if [ -f "$PAGE" ]; then
  N=$(grep -o 'data-state="unavailable"' "$PAGE" | wc -l | tr -d ' ')
  U=$(grep -o 'data-status="unavailable"' "$PAGE" | wc -l | tr -d ' ')
  [ "$N" -ge 3 ] && pass "unavailable metric/budget states visible (n=$N)" || fail "too few unavailable states on the page (n=$N)"
  [ "$U" -ge 1 ] && pass "unavailable status chip visible (n=$U)" || fail "no unavailable status chip on the page"
  grep -q 'preserved under ruling' "$PAGE" && pass "preserved artifact state visible" || fail "preserved state missing"
  grep -q 'ks run --image' "$PAGE" && pass "empty state teaches a command" || fail "empty state teaches nothing"
  for s in running parked checkpointing resuming aborted failed; do
    grep -q ">$s<" "$PAGE" || fail "status pill missing: $s"
  done
  pass "all six status pills rendered (any missing failed above)"
else
  fail "dist/design-system/index.html not built"
fi

echo "--- 3. tokens are the only source of color ---"
LEAKS=$(grep -rnE '#[0-9a-fA-F]{6}\b' src/ --include='*.astro' --include='*.css' -l | grep -v fonts.css || true)
[ -z "$LEAKS" ] && pass "no hex literals in src (tokens.json is the single source)" || fail "hex literals outside tokens.json: $LEAKS"

ELAPSED=$(( $(date +%s) - START ))
echo "elapsed: ${ELAPSED}s"
if [ "$FAILS" -eq 0 ]; then echo "GATE W1: GREEN - the system enforces its own laws"; exit 0; fi
echo "GATE W1: RED - $FAILS assertion(s) failed"; exit 1
