# JOURNAL — keepstate-web

## 2026-08-19 — Repo born; design inventoried; W0 awaiting Azure approval
- Repo created per the master prompt: CLAUDE.md (web constitution),
  WEBPLAN.md (phases W0-W6), gates/, docs/, infra/, design/ with all 22
  Claude Design composites + support.js from ks-frontend.zip (exported
  2026-08-10).
- Inventory: 21 page composites in dc format (inline styles, {{ }}
  slots, sc-for loops, screen-switcher composites for multi-state
  pages). Product Pages is ONE tabbed template covering the four
  product pages. Auth & System States carries sign-in, waitlist,
  invite-pending, 404, 500, banners. Legal & Support carries Privacy,
  Terms, AUP, DPA, Subprocessors, support desk.
- Gaps recorded in BACKLOG.md (G1-G7): no Compatibility/About/Press/
  Contact/Changelog composites; consoles are post-launch spec; no
  tokens file (extract at W0); Google Fonts + support.js are preview
  plumbing, never production; Status page is designed but unplanned.
- Readiness verified read-only: az logged in (Azure subscription 1),
  gh logged in as esrygrtc, node v22.23.1.
- HALTED at the tripwire: W0 plan presented (SWA Standard ~$9/mo,
  West Europe, resource group; GitHub repo esrygrtc/keepstate-web).
  No Azure resource exists yet. Next action: on founder approval, run
  scaffold + infra scripts + pipeline, then gate W0 + sabotage.

## 2026-08-19 — Azure operator account created; admin handover pending
- Founder directive: pause web phases, create a KS-scoped Azure user as
  admin, touch NOTHING else on Azure. Executed exactly three things:
  1. Entra user `ks@devplaybliss.onmicrosoft.com` ("KeepState Ops",
     objectId 3c753fa4-b4e5-4a0c-9900-52520305277c), password change
     forced at first sign-in. First create attempt failed on Entra's
     password-cannot-contain-username rule (prefix "Ks-"); retried with
     a compliant generator.
  2. Resource groups `keepstate-web-rg` and `keepstate-rg` (westeurope,
     $0) — the scopes the rights attach to. Website resources go in the
     first; future product infra (customer VMs) in the second.
  3. Owner for ks on those two groups ONLY. Verified: exactly two role
     assignments, zero directory roles. Subscription assignment count
     unchanged apart from ks.
- Credentials: ~/Desktop/ks-azure-login.txt (mode 600), password never
  entered the conversation or the repo. Founder deletes it after first
  sign-in.
- Known limit by design: ks cannot create NEW resource groups; a future
  RG is an admin moment. Everything W0-W6 needs fits in the two groups.
- Next action: founder logs out of admin az, logs in as ks; then resume
  Phase W0 (SWA Standard ~$9/mo in keepstate-web-rg awaits approval,
  which the founder has implicitly queued but I will re-confirm cost at
  creation time per the tripwire).

## 2026-08-19 — Phase W0 GREEN: the pipeline is real
- Logged in as ks (sees exactly two groups). Naming law applied: every
  Azure name from now on is ks-*; the two admin-created RGs keep their
  keepstate-* names as a recorded exception (ADR-W1) until an admin
  moment recreates them.
- Built: Astro scaffold, tokens.json extraction (script, reproducible),
  self-hosted fonts, holding page, CI with PR previews + auto staging +
  dispatch-only production, idempotent infra script, ADR-W1.
- Azure created: SWA ks-web (Standard, westeurope, ~$9/mo) in
  keepstate-web-rg. Token piped to GitHub secrets, never echoed.
- GitHub repo esrygrtc/ks-web is PUBLIC: branch protection (required
  build check) needs public on the free plan, and CI-blocks-merge is
  gate law. Founder may flip visibility at the cost of protection.
- Gate W0 GREEN (6/6): staging got the probe with no human action,
  production stayed untouched, workflow graph has no auto path to
  production, infra re-ran idempotently. Sabotage GREEN: broken page
  PR failed CI, merge state BLOCKED, merge refused.
- Next action: tag web-0-green; Phase W1 (component sheet) on founder go.

## 2026-08-19 — Naming migration: the estate is ks-* everywhere
- Founder switched CLI to admin; executed the recreate-move-regrant-
  delete sequence. az resource move printed ResourceGroupNotInExpectedState
  yet the move had succeeded (verified: SWA in ks-web-rg, old groups
  gone, site 200 throughout). Lesson: verify state, not error text.
- ks now holds exactly two role assignments, both ks-* groups. ADR-W1
  exception paragraph closed. infra/create-swa.sh and gate-w0 updated
  to the new group name; the push testing this doubles as proof the
  deployment token survived the move.
- Founder to switch CLI back to ks; then Phase W1 begins.

## 2026-08-19 — Phase W1 GREEN: the sheet is code and the laws bite
- 18 tokens-only components, /design-system with every state, 13 law
  tests in CI. Gate learned two lessons the honest way: its pill grep
  was stricter than the page's whitespace (fixed in the component,
  rule-7 disclosed, gate untouched), and its git-checkout restore
  assumes a committed subject (first sabotage ran on a dirty bench).
- Token pass 2: 12 sheet-verified colors promoted to names via the
  extraction script; src contains zero hex literals, gate-enforced.
- Next: tag web-1-green, push; Phase W2 (marketing pages, copy
  verbatim, sync-claims for Proof) on founder go.

## 2026-08-19 — Phase W2 GREEN: nineteen honest pages
- Seven parallel agents built eleven pages from their composites; four
  built by hand (about/press/contact simple per G2 default, proof/
  compatibility generated). Every agent independently refused the
  composites' demo data: fake gate tags, sample uptimes, invented
  grantees, fictional pilots. The two-agent inconsistency (pen test
  kept vs refused) was reconciled to the stricter treatment.
- sync-claims is live: Proof and Compatibility render 16 claims, 2
  matrix rows, 11 tags from the product repo; hand edits fail the hash
  check (sabotage-proven, and the sabotage found check-sync's own
  process.exit bug stranding backups).
- Gate W2 GREEN (16 asserts), sabotage GREEN (both lints + hash check
  bite). 139 verbatim design lines held by the copy lint.
- Founder review flags: security@ mail routing (W-1), certification
  records (W-2), careers salary terms.
- Next: tag web-2-green, push, deploy staging for founder review;
  Phase W3 (docs + Ledger) on founder go.

## 2026-08-19 — W2 postscript: two pipeline lessons before the tag settled
- check-sync could not run on GitHub runners: it read the builder's
  local product repo path. First fix (clone in CI) died on a fact that
  changed under us: esrygrtc/ks is PRIVATE now (it was public in July;
  gate 7's quickstart cloned it anonymously). Final architecture:
  sync-claims vendors its sources into design/.sync on every live run;
  CI regenerates from the snapshot (hand-edit detection, secretless);
  freshness against the live repo stays gate-w2's local assertion.
- PRODUCT-SIDE FLAG for the founder: the private flip breaks the
  product's own public-quickstart story (claims.md cites a stranger's
  clean clone). Not this repo's scope; reported, not touched.
- gh run watch --exit-status returns 0 for already-completed runs; one
  "CI GREEN" line in the session transcript was false. Verdicts now
  read the conclusion field. web-2-green was deleted and re-tagged
  twice, landing on the commit whose pipeline is actually green.

## 2026-08-20 — Phase W3 GREEN: docs, search, and the Ledger
- sync-docs joins sync-claims: quickstart/limits/CLI/API/troubleshooting/
  changelog all generated from product sources, snapshot-vendored,
  hash-checked. The real CLI is the only CLI documented; the composite's
  aspirational syntax went to BACKLOG G9 as roadmap input.
- Gate W3 GREEN incl. a live-browser leg (Pagefind returns quickstart
  for "resume"; a copy button click yields real clipboard bytes).
  First run RED because /docs had no search box: the gate found it.
- Sabotage GREEN: corrupted sync hash cannot pass.
- Upstream: one product-repo docs commit (OPERATOR troubleshooting row
  caught up with v0.1.1). Legal pages shipped draft-marked (G8 ruling);
  founder legal review required before cutover.
- Next: tag web-3-green; Phase W4 (forms, functions, console shell)
  needs the leads storage account (~cents/mo) and the email decision.

## 2026-08-20 — Phase W4 built, 19/20 proven, blocked on two gate amendments
- Leads path live on staging: durable-before-delivered proven for all
  four forms, dead email step run live (unconfigured), honeypot and
  rate limit proven (after the gate caught the x-forwarded-for port
  bug), console shell honest in three states.
- Gate defects found by running: OAuth assertion sees only hop 1 of
  SWA's 3-hop chain (lands on github.com at hop 3, measured); sabotage
  sleep 20s vs measured 7-10min app-setting propagation. Both in
  BLOCKED.md with precise amendments; only the founder amends gates.
- Live accidental proof during manual verification: nine submissions
  against a broken store all failed loudly and stored nothing.
- web-4-green NOT tagged. Awaiting: two amendments + KS_EMAIL_KEY.
- Proceeding to W5 per the all-phases directive.

## 2026-08-20 — Phase W5: product green on the real host, gate blocked on probes
- Every budget met on staging: 100/100 on all four gate pages, CLS
  0.000, axe zero critical, full header set on GET. The budgets earned
  their keep: they found the light-band-5 fidelity+contrast bug, the
  chip contrast, color-only links, a missing landmark, and font-swap
  CLS; each fix is in the phase doc with its measurement.
- Gate blocked on three probe defects (HEAD vs GET, axe API misuse,
  uncompressed localhost); BLOCKED.md carries exact amendments and the
  evidence. No tag.
- Next: W6's machine-doable parts (cache policy, k6, rollback, uptime
  script); DNS + production deploy + email key + amendments = founder
  return list.
