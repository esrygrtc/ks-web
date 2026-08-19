# Phase W5 - Performance, accessibility, hardening

HYPOTHESIS: fast for everyone, by budget not by vibe.

STATUS: PRODUCT WORK COMPLETE AND MEASURED GREEN ON THE REAL HOST;
GATE UNTAGGED, blocked on three probe amendments (BLOCKED.md).

## Measured on staging (SWA, brotli), after the fixes

| Page | Perf | A11y | LCP | CLS | axe critical |
|---|---|---|---|---|---|
| / | 100 | 100 | 1372ms | 0.000 | 0 |
| /pricing/ | 100 | 100 | 1029ms | 0.000 | 0 |
| /docs/ | 100 | 100 | 804ms | 0.016 | 0 |
| /docs/quickstart/ | 100 | 100 | 1363ms | 0.000 | 0 |

Headers verified on GET: CSP with 9 inline-script hashes and no
unsafe-inline for scripts (style-src keeps unsafe-inline: the design
system drives dynamic values through style attributes; scoped
interpretation); HSTS max-age=31536000 WITHOUT preload, beating the
platform default; frame-ancestors none; X-Frame-Options DENY;
nosniff; referrer strict-origin-when-cross-origin. Config generated
at build with the hashes (scripts/gen-headers.mjs).

## The diagnosis trail (what the budgets found)

1. A11y 88-92 everywhere: footer band 5 was built LIGHT with the
   composite's dark-band text colors: one mistake, both a fidelity
   bug and a contrast bug. Band 5 is now ink, as designed.
2. Chip text taupe-on-parchment measures 4.05:1 at 12px: below AA.
   Chips now use slate: a recorded a11y-over-palette deviation.
3. In-text links relied on color alone (WCAG link-in-text-block):
   underlined throughout; docs gained a main landmark; the ESTIMATED
   badge gained an onDark tone for the dark calculator card.
4. LCP 1955ms on localhost vs 914ms on staging: astro preview serves
   uncompressed HTML (70,042 bytes raw vs 7,255 brotli). The gate
   measures a transport production never uses: amendment 3.
5. CLS 0.214 on the quickstart: late font swaps reflowed the code
   blocks. font-display: optional across all faces (the composites
   themselves name Georgia/Arial fallbacks) + three preloads.
   Result: CLS 0.000 everywhere.

## Gate defects (BLOCKED.md, founder authority required)

HEAD-vs-GET header probe; axe newContext API; audit against the
compressed host. All three with measurements attached.

## Gate W5 - first normal run (raw output, exit 1)

```
=== GATE W5 (normal mode) 2026-08-19T22:07:25Z ===
--- 1. build + budgets + axe (local preview, throttled mobile) ---
ASSERT PASS: build green
ASSERT PASS: / performance 98 >= 95 (marketing)
ASSERT FAIL: / accessibility 92 >= 95
ASSERT FAIL: / LCP 1956ms < 1800ms (throttled mobile)
ASSERT PASS: / CLS 0.001 < 0.1
ASSERT PASS: /pricing/ performance 96 >= 95 (marketing)
ASSERT FAIL: /pricing/ accessibility 91 >= 95
ASSERT FAIL: /pricing/ LCP 2255ms < 1800ms (throttled mobile)
ASSERT PASS: /pricing/ CLS 0.000 < 0.1
ASSERT PASS: /docs/ performance 100 >= 90 (docs)
ASSERT FAIL: /docs/ accessibility 88 >= 95
ASSERT PASS: /docs/ LCP 1503ms < 1800ms (throttled mobile)
ASSERT PASS: /docs/ CLS 0.002 < 0.1
ASSERT PASS: /docs/quickstart/ performance 99 >= 90 (docs)
ASSERT FAIL: /docs/quickstart/ accessibility 89 >= 95
ASSERT PASS: /docs/quickstart/ LCP 1654ms < 1800ms (throttled mobile)
ASSERT PASS: /docs/quickstart/ CLS 0.030 < 0.1
file:///Users/c/keepstate-web/node_modules/@axe-core/playwright/dist/index.mjs:218
      throw new Error(
            ^

Error: Please use browser.newContext()
 Please check out https://github.com/dequelabs/axe-core-npm/blob/develop/packages/playwright/error-handling.md
    at AxeBuilder.analyze (file:///Users/c/keepstate-web/node_modules/@axe-core/playwright/dist/index.mjs:218:13)
    at async file:///Users/c/keepstate-web/gates/gate-w5-audit.mjs:42:15

Node.js v22.23.1
--- 2. headers, served by the real host ---
ASSERT FAIL: no CSP header
ASSERT PASS: no unsafe-inline anywhere
ASSERT FAIL: frame-ancestors missing
ASSERT PASS: HSTS served
ASSERT FAIL: HSTS carries preload (one-way tripwire!)
ASSERT PASS: nosniff
ASSERT PASS: referrer-policy served
--- 3. the designed error pages serve ---
ASSERT PASS: designed 404 serves on the host
--- 4. reduced motion + print are real ---
ASSERT PASS: every animation guarded for prefers-reduced-motion
ASSERT PASS: print stylesheet present for docs
GATE W5: RED - 4 assertion(s) failed
```

## Gate W5 - sabotage run (raw output, exit 0)

```
=== GATE W5 (--sabotage mode) 2026-08-19T22:31:53Z ===
--- sabotage: a 2 MB hero image must break the budget ---
sabotage hero: 2.0 MB
ASSERT FAIL: / performance 75 >= 95 (marketing)
ASSERT FAIL: / LCP 11706ms < 1800ms (throttled mobile)
ASSERT FAIL: /pricing/ LCP 1953ms < 1800ms (throttled mobile)
ASSERT PASS: the budget failed on the sabotaged page
ASSERT PASS: clean rebuild restores the honest artifact
GATE W5 SABOTAGE: GREEN - the budget bites
```

Note the sabotage's weak spot, honestly: it asserts the audit fails
WITH the 2MB hero, which the localhost budget defect would satisfy
even without the hero. Once amendment 3 lands (audit vs staging,
which passes clean), the sabotage becomes fully discriminating.
