#!/bin/bash
# HYPOTHESIS: the pipeline is real end to end. A trivial commit reaches
# the staging URL automatically; the production deploy is manual-approval
# only; infra scripts re-run idempotently.
#
# Sabotage mode (--sabotage): a syntax-broken page on a PR branch must be
# BLOCKED from merging by the required build check. GREEN iff blocked.
#
# WORLD 1 (macOS) script: portable clock, no GNU-isms. Hard cap 1500 s.
set -u
cd "$(dirname "$0")/.."
REPO=esrygrtc/ks-web
PROD=https://icy-wave-0eefe5403.7.azurestaticapps.net
STAGING=https://icy-wave-0eefe5403-staging.westeurope.7.azurestaticapps.net
START=$(date +%s)
MODE="${1:-normal}"
FAILS=0
pass() { echo "ASSERT PASS: $*"; }
fail() { echo "ASSERT FAIL: $*"; FAILS=$((FAILS+1)); }
left() { echo $(( 1500 - ($(date +%s) - START) )); }
guard() { [ "$(left)" -gt 60 ] || { echo "GATE W0: ABORT - timeout budget exhausted (exit 75)"; cleanup; exit 75; }; }

cleanup() {
  git checkout -q main 2>/dev/null || true
  git branch -D w0-sabotage 2>/dev/null || true
  git push -q origin --delete w0-sabotage 2>/dev/null || true
}
trap cleanup EXIT

echo "=== GATE W0 ($MODE mode) $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="

if [ "$MODE" = "--sabotage" ]; then
  echo "--- sabotage: a broken page must be unmergeable ---"
  git checkout -q -b w0-sabotage
  printf -- '---\nthrow new Error("w0 sabotage: this page must not build");\n---\n<html></html>\n' > src/pages/sabotage.astro
  git add src/pages/sabotage.astro
  git commit -q -m "w0 sabotage: deliberately broken page"
  git push -q -u origin w0-sabotage
  PR=$(gh pr create --repo "$REPO" --title "w0 sabotage (must be blocked)" --body "gate artifact; never merge" --head w0-sabotage 2>/dev/null | grep -oE '[0-9]+$')
  echo "sabotage PR #$PR opened; waiting for the build check to fail"
  CONC=""
  while [ -z "$CONC" ] && [ "$(left)" -gt 90 ]; do
    sleep 20
    CONC=$(gh pr checks "$PR" --repo "$REPO" 2>/dev/null | awk '$1=="build"{print $2}' | head -1)
    [ "$CONC" = "pending" ] && CONC=""
  done
  echo "build check concluded: ${CONC:-never}"
  [ "$CONC" = "fail" ] && pass "broken build fails CI" || fail "build check did not fail (got: ${CONC:-nothing})"
  MS=$(gh pr view "$PR" --repo "$REPO" --json mergeStateStatus -q .mergeStateStatus)
  [ "$MS" = "BLOCKED" ] && pass "merge state is BLOCKED" || fail "merge state is $MS, want BLOCKED"
  if gh pr merge "$PR" --repo "$REPO" --squash 2>/dev/null; then
    fail "merge SUCCEEDED despite red CI - protection is not real"
  else
    pass "non-admin merge attempt refused"
  fi
  gh pr close "$PR" --repo "$REPO" -d 2>/dev/null || true
  rm -f src/pages/sabotage.astro
  if [ "$FAILS" -eq 0 ]; then
    echo "GATE W0 SABOTAGE: GREEN - a broken commit cannot reach main"
    exit 0
  fi
  echo "GATE W0 SABOTAGE: RED - $FAILS assertion(s) failed"
  exit 1
fi

echo "--- 1. trivial commit reaches staging automatically ---"
NONCE=$(openssl rand -hex 8)
echo "pipeline-probe $NONCE" > public/pipeline-probe.txt
git add public/pipeline-probe.txt
git commit -q -m "w0 gate probe: $NONCE"
git push -q
echo "pushed probe $NONCE to main; polling staging"
GOT=""
while [ -z "$GOT" ] && [ "$(left)" -gt 90 ]; do
  sleep 20
  BODY=$(curl -fsS --max-time 10 "$STAGING/pipeline-probe.txt" 2>/dev/null || true)
  echo "$BODY" | grep -q "$NONCE" && GOT=yes
done
[ "$GOT" = yes ] && pass "staging serves the probe with no human action" \
                 || fail "staging never served probe $NONCE"

echo "--- 2. production is manual-only ---"
grep -A1 'deploy-production:' .github/workflows/ci.yml | grep -q "github.event_name == 'workflow_dispatch'" \
  && pass "workflow graph: production job exists only under workflow_dispatch" \
  || fail "workflow graph: production job not dispatch-gated"
AUTO_PATHS=$(awk '/deployment_environment/{print}' .github/workflows/ci.yml | wc -l | tr -d ' ')
PRODBODY=$(curl -fsS --max-time 10 "$PROD/pipeline-probe.txt" 2>/dev/null || echo ABSENT)
echo "$PRODBODY" | grep -q "$NONCE" \
  && fail "production serves the new probe WITHOUT a manual deploy" \
  || pass "production untouched by the main push (probe absent there)"

echo "--- 3. infra idempotency ---"
R1=$(bash infra/create-swa.sh 2>&1); S1=$?
R2=$(bash infra/create-swa.sh 2>&1); S2=$?
N=$(az staticwebapp list -g ks-web-rg --query 'length(@)' -o tsv)
[ "$S1" -eq 0 ] && [ "$S2" -eq 0 ] && pass "infra script exits 0 twice" || fail "infra script rc=$S1/$S2"
[ "$N" = "1" ] && pass "still exactly one SWA after re-runs (n=$N)" || fail "SWA count $N, want 1"
echo "$R2" | grep -q '^exists:' && pass "second run reports exists, creates nothing" || fail "second run did not report exists"

if [ "$FAILS" -eq 0 ]; then
  echo "GATE W0: GREEN - the pipeline is real end to end"
  exit 0
fi
echo "GATE W0: RED - $FAILS assertion(s) failed"
exit 1
