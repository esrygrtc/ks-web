# Phase W1 - The component sheet becomes code

HYPOTHESIS: the design system enforces its own laws. A null-fed metric
card renders "unavailable" and cannot render 0; a status chip without
a feed cannot be green; numbers without provenance refuse to render;
every state is visible on /design-system.

## Built

- 18 components in src/components/, driven only by design/tokens.json
  (gate-verified: zero hex literals in src). Second extraction pass
  promoted 12 sheet-verified colors from paletteExtended to named
  tokens (moss, claretDeep, blushBg, track, ...); 10 hexes remain
  extended and unused.
- /design-system renders every state: three law demos (a measured 0
  beside an unavailable meter), six status pills from the sheet's
  exact map (aborted and failed are never the same pill), the chip in
  all three states, preserved artifact with no delete affordance,
  type-to-confirm modal, empty state teaching a command, skeletons.
- 13 law tests (Vitest + Astro container), wired into CI before the
  build step. Screenshot: docs/assets/design-system-w1.png

## The run history, honestly

1. v1 normal run RED (6): the gate greps for `>running<` and the pill
   rendered `running </span>`. The page was right in substance, the
   markup was loose. Fixed in the COMPONENT (whitespace-only: status
   text flush against its tags), disclosed per rule 7 before re-run.
   The gate was not edited.
2. First sabotage run RED: the gate restores the sabotaged guard via
   git checkout, and the components were not yet committed, so there
   was nothing to restore from. A gate that restores via git assumes a
   committed subject; the bench was dirty. Guard restored by hand,
   everything committed, re-run.
3. Normal GREEN (13 named law tests + page states + token purity),
   sabotage GREEN (guard off, the null-cannot-render-0 test fails;
   guard restored, suite green again).

## Gate W1 - normal run (raw output, exit 0)

```
=== GATE W1 (normal mode) 2026-08-19T17:01:36Z ===
--- 1. the law tests exist, by name, and pass (rule 13: names, not counts) ---
ASSERT PASS: law test green: "metric card with null data renders unavailable"
ASSERT PASS: law test green: "metric card with null data cannot render 0"
ASSERT PASS: law test green: "status chip without feed renders UNAVAILABLE"
ASSERT PASS: law test green: "green is impossible without live data"
ASSERT PASS: law test green: "metric card without badge or evidence link refuses to render"
ASSERT PASS: law test green: "a measured zero renders 0: a zero is a measurement"
ASSERT PASS: law test green: "a preserved artifact renders no delete affordance at all"
ASSERT PASS: full suite green (13 tests)
--- 2. /design-system renders every unavailable state ---
ASSERT PASS: unavailable metric/budget states visible (n=3)
ASSERT PASS: unavailable status chip visible (n=1)
ASSERT PASS: preserved artifact state visible
ASSERT PASS: empty state teaches a command
ASSERT PASS: all six status pills rendered (any missing failed above)
--- 3. tokens are the only source of color ---
ASSERT PASS: no hex literals in src (tokens.json is the single source)
elapsed: 2s
GATE W1: GREEN - the system enforces its own laws
```

## Gate W1 - sabotage run (raw output, exit 0)

```
--- sabotage: Law-1 guard disabled; the tests must catch it ---
ASSERT PASS: tests fail when the guard is disabled
=== GATE W1 (--sabotage mode) 2026-08-19T17:00:19Z ===
--- sabotage: Law-1 guard disabled; the tests must catch it ---
ASSERT PASS: tests fail when the guard is disabled
ASSERT PASS: the failing test is the null-cannot-render-0 law itself
ASSERT PASS: guard restored; tests green again
GATE W1 SABOTAGE: GREEN - the law tests bite
```
