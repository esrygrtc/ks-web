#!/bin/bash
# HYPOTHESIS: fast for everyone, by budget not by vibe. Lighthouse
# budgets hold on key pages (performance >= 95 marketing / >= 90 docs,
# accessibility >= 95, LCP < 1.8 s, CLS < 0.1 on throttled mobile); axe
# reports zero critical violations; security headers are served by the
# real host (CSP without unsafe-inline for scripts, HSTS without
# preload, frame-ancestors none, nosniff, referrer-policy).
#
# Sabotage (--sabotage): inject a 2 MB unoptimized hero image into the
# built home page; the performance budget must fail. GREEN iff it does.
#
# WORLD 1 (macOS): portable clock. Hard cap 1500 s (Lighthouse is slow).
set -u
cd "$(dirname "$0")/.."
STAGING="${GATE_STAGING:-https://icy-wave-0eefe5403-staging.westeurope.7.azurestaticapps.net}"
MODE="${1:-normal}"
FAILS=0
pass() { echo "ASSERT PASS: $*"; }
fail() { echo "ASSERT FAIL: $*"; FAILS=$((FAILS+1)); }
cleanup() { pkill -f 'astro preview' 2>/dev/null || true; }
trap cleanup EXIT
export CHROME_PATH="${CHROME_PATH:-$(node -e "console.log(require('playwright').chromium.executablePath())")}"

echo "=== GATE W5 ($MODE mode) $(date -u '+%Y-%m-%dT%H:%M:%SZ') ==="

if [ "$MODE" = "--sabotage" ]; then
  echo "--- sabotage: a 2 MB hero image must break the budget ---"
  npm run build >/tmp/w5-sab-build.log 2>&1 || { echo "GATE W5 SABOTAGE: ABORT - build failed (exit 75)"; exit 75; }
  python3 - <<'PY'
import os, random, struct, zlib
# A genuinely unoptimized 2 MB PNG: random noise, incompressible.
w = h = 820
raw = b''.join(b'\x00' + bytes(random.getrandbits(8) for _ in range(w * 3)) for _ in range(h))
def chunk(t, d): 
    c = struct.pack('>I', len(d)) + t + d
    return c + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
png = (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
       + chunk(b'IDAT', zlib.compress(raw, 0)) + chunk(b'IEND', b''))
open('dist/sabotage-hero.png', 'wb').write(png)
print(f'sabotage hero: {len(png)/1e6:.1f} MB')
s = open('dist/index.html').read()
s = s.replace('<main', '<img src="/sabotage-hero.png" alt="sabotage hero" style="width:100%"><main', 1)
open('dist/index.html', 'w').write(s)
PY
  (npx astro preview --port 4321 >/tmp/w5-preview.log 2>&1 &)
  sleep 4
  if node gates/gate-w5-audit.mjs > /tmp/w5-sab-audit.log 2>&1; then
    fail "budgets PASSED with a 2 MB unoptimized hero on the home page"
  else
    grep -E 'ASSERT FAIL.*(/ perf|/ LCP|/ performance|LCP|performance)' /tmp/w5-sab-audit.log | head -3
    pass "the budget failed on the sabotaged page"
  fi
  pkill -f 'astro preview' 2>/dev/null || true
  npm run build >/dev/null 2>&1 && pass "clean rebuild restores the honest artifact" || fail "rebuild failed"
  if [ "$FAILS" -eq 0 ]; then echo "GATE W5 SABOTAGE: GREEN - the budget bites"; exit 0; fi
  echo "GATE W5 SABOTAGE: RED - $FAILS assertion(s) failed"; exit 1
fi

echo "--- 1. build + budgets + axe (local preview, throttled mobile) ---"
npm run build >/tmp/w5-build.log 2>&1 && pass "build green" || { fail "build failed"; }
(npx astro preview --port 4321 >/tmp/w5-preview.log 2>&1 &)
sleep 4
node gates/gate-w5-audit.mjs || FAILS=$((FAILS+1))
pkill -f 'astro preview' 2>/dev/null || true

echo "--- 2. headers, served by the real host ---"
H=$(curl -fsSI "$STAGING/")
echo "$H" | grep -qi 'content-security-policy' && pass "CSP header served" || fail "no CSP header"
echo "$H" | grep -i 'content-security-policy' | grep -q "unsafe-inline'" && {
  echo "$H" | grep -i 'content-security-policy' | grep -qE "script-src[^;]*unsafe-inline" && fail "script-src carries unsafe-inline" || pass "unsafe-inline confined to style-src (scoped interpretation, phase doc)"
} || pass "no unsafe-inline anywhere"
echo "$H" | grep -qi "frame-ancestors 'none'" && pass "frame-ancestors none" || fail "frame-ancestors missing"
echo "$H" | grep -qi 'strict-transport-security' && pass "HSTS served" || fail "HSTS missing"
echo "$H" | grep -i 'strict-transport-security' | grep -qi 'preload' && fail "HSTS carries preload (one-way tripwire!)" || pass "HSTS without preload"
echo "$H" | grep -qi 'x-content-type-options: nosniff' && pass "nosniff" || fail "nosniff missing"
echo "$H" | grep -qi 'referrer-policy' && pass "referrer-policy served" || fail "referrer-policy missing"

echo "--- 3. the designed error pages serve ---"
curl -s "$STAGING/definitely-not-a-page-$RANDOM" | grep -q 'The address does not exist' && pass "designed 404 serves on the host" || fail "designed 404 not serving"

echo "--- 4. reduced motion + print are real ---"
grep -rn 'animate-' src/components/ src/pages/ 2>/dev/null | grep -v 'motion-reduce' | grep -q . && fail "an animation lacks a motion-reduce guard" || pass "every animation guarded for prefers-reduced-motion"
grep -q 'media="print"' src/layouts/Docs.astro && pass "print stylesheet present for docs" || fail "no print stylesheet"

if [ "$FAILS" -eq 0 ]; then echo "GATE W5: GREEN - fast for everyone, by budget"; exit 0; fi
echo "GATE W5: RED - $FAILS assertion(s) failed"; exit 1
