# Phase W3 - Docs and content systems

HYPOTHESIS: a stranger can navigate from landing to a runnable
quickstart. Zero broken links; search returns the quickstart for
"resume"; every code block has a working copy button, tested in a
real browser; synced content is hash-checked against its sources.

## Built (37 pages now)

- sync-docs: quickstart, limits, CLI (15 real verbs from the binary's
  own usage strings), API (10 real routes from the daemon's route
  table), troubleshooting (operator manual), changelog (11 tag
  bodies). Snapshot-vendored like claims; check-sync-docs enforces
  byte-identical regeneration.
- Three-column docs layout, build-time copy buttons (rehype), Pagefind
  behind cmd-K, concepts/Claude-Code-guide/FAQ, The Ledger with the
  DRAFT-marked first post (866 words, noindex), five legal pages +
  support (BACKLOG G8 ruling: designed but unscheduled; W4 forms need
  terms, so they ship draft-marked for founder legal review).

## The law the docs enforce: the real CLI is the only CLI

The composite's examples used an aspirational CLI (ks steer, fork
s_7f3a@40, dollar budgets, a --bundle flag). None of it shipped: the
CLI reference is generated from the binary's help strings and the
guides use only gate-tested commands. The aspirational surface is
recorded in BACKLOG G9 as product roadmap input.

## Found en route

- Product doc drift: OPERATOR.md's troubleshooting table still called
  the ks ps defect cosmetic and current (fixed in v0.1.1). Corrected
  upstream in the product repo before syncing; publishing known-wrong
  advice loses to the read-only preference.
- Gate-w3's browser leg found /docs had NO search box: CmdK existed
  only on the design-system page. Fixed in the layout; the gate was
  right and the first run was RED for exactly the right reason.
- Three lint refinements, each disclosed pre-run: markdown fences are
  exempt from the em-dash law (quoted gate-tested bytes are not house
  prose); sync-docs rewrites product-internal links (23 would-be 404s);
  lint-links strips script bodies (a template literal is not a link).

## Gate W3 - normal run (raw output, exit 0)

```
=== GATE W3 (normal mode) 2026-08-19T21:30:54Z ===
--- 1. synced content is fresh against its sources ---
ASSERT PASS: claims sync fresh
ASSERT PASS: docs sync fresh (quickstart, limits, CLI, API, changelog)
--- 2. build + full link lint ---
ASSERT PASS: site builds with search index
link lint: clean (37 pages, no broken links, no orphans)
ASSERT PASS: link lint green
ASSERT PASS: em-dash lint green
ASSERT PASS: copy fidelity green
--- 3. the stranger's path exists in the built HTML ---
ASSERT PASS: landing links to docs
ASSERT PASS: quickstart carries the gate-tested success marker
ASSERT PASS: static check: 5 copy buttons on 5 code blocks
--- 4. browser leg: search + live copy ---
ASSERT PASS: search "resume" returns the quickstart (8 results)
ASSERT PASS: every code block has a copy button (5/5)
ASSERT PASS: copy button copies real content (brew list lima >/dev/null 2>&1 || brew i...)
--- 5. the Ledger draft is marked ---
ASSERT PASS: draft post visibly marked on the Ledger index
GATE W3: GREEN - landing to runnable quickstart, no dead ends
```

## Gate W3 - sabotage run (raw output, exit 0)

```
=== GATE W3 (--sabotage mode) 2026-08-19T21:31:20Z ===
--- sabotage: a corrupted sync hash must fail the check ---
ASSERT PASS: hash check fails on the corrupted quickstart sync hash
ASSERT PASS: restored; hash check green again
GATE W3 SABOTAGE: GREEN - corrupted sync cannot pass
```
