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

## 2026-08-20 — All phases complete to the machine's limit; the founder's return list
The all-phases directive is discharged: W0-W3 tagged green; W4 and W5
built, measured, and blocked only on gate amendments that need founder
authority; W6's machine half built and rehearsed (rollback cycle 165 s
round trip with a clean abort case; k6 rehearsed at 50 VUs: 21,346
requests, zero failures, p95 236 ms).

### The founder's return list, in order
1. RULE ON GATE AMENDMENTS (BLOCKED.md, exact diffs included):
   w4: OAuth chain-following probe; sabotage vector or poll.
   w5: GET header probe; axe newContext; audit against the compressed
   host. On your written ok I apply, re-run all gates whole, tag
   web-4-green and web-5-green.
2. EMAIL: set KS_EMAIL_KEY/TO/FROM in SWA settings (Resend-compatible;
   you add the key, it never transits this conversation). Closes the
   w4 abort leg. Also W-1: real mail routing for security@keepstate.ai.
3. CONTENT REVIEW before production: Proof page, the DRAFT Ledger post,
   legal pages (draft-marked), security/enterprise cert rows (W-2),
   careers role + salary.
4. PRODUCTION DEPLOY: your manual dispatch of the ci workflow.
5. CUTOVER (docs/cutover-dns.md): set the two DNS records, run
   infra/add-domains.sh, approve the ~$2-5/mo uptime resources, run
   infra/create-uptime.sh, test-fire the alert, then gates/gate-w6.sh
   + --sabotage, tag web-6-green, launch quietly, send the ten emails.
6. PRODUCT SIDE, when convenient: the private-repo flip broke the
   public-quickstart story (gate-7 B5); the han/Apache-2.0 extraction
   waits on the first design partner.

## 2026-08-20 — Fidelity rebuild: /proof and /compatibility re-dressed in the composite's shell
Per the founder's fidelity ruling, /proof now mirrors design/Proof.dc.html
1:1: composite header (no footer, composite has none), hero + mono meta
line, filter pills with the DCLogic interaction in vanilla JS, the
claims table with status pills and diamond tag links, the absorption
matrix, the slate findings-archive band, and the italic CTA. UI Law 4
held throughout: every row, pill, tag, matrix cell, and archive card
renders from src/generated/proof.json; the composite's placeholder
claims (G-101, 118/121, F-061...) were treated as placeholders its
shell renders real data into. antiClaims render as "not claimed" rows
(the design's muted pill + "no gate yet" treatment); the closing field
is the archive band's prose; the tag list became the archive cards,
which restores every /proof#gate-N deep link the docs use.
/compatibility (no composite of its own) is styled as a sibling of the
rebuilt Proof. design/copy/proof.txt created (11 verbatim lines). All
four lints + 13 law tests green. Surprise: none of the composite's
hexes were missing from tokens.json. Next action: founder content
review of the new Proof shell alongside return-list item 3.

## 2026-08-20 — Fidelity rebuild: /status and /ledger re-dressed in the composite's shell
/status now mirrors design/Status.dc.html in its UNAVAILABLE mode (the
composite's own third view, and the only honest one with no feed):
hero dot + clamp(34,4.8vw,52) title, mono system line, the uptime card
with per-surface pills, mono "unavailable" figures, 45-bar strips,
legend, and the three closing cards at composite sizes. Carve-out (a)
overrode the composite's leaks: its unavailable view still paints
days 4-45 green and keeps INC-011..014 + invented incident notes; ours
renders every bar gray ("no data recorded"), "no probe data recorded"
notes, an empty incident history, and the incident-definition card
truncated before "Four of the incidents below". /status.json ships as
a real static file so the Machine-readable card stops advertising a
404; region stays westeurope (composite samples eu-central-1).
/ledger and /ledger/[slug] now mirror The Ledger.dc.html: 60px
masthead, tag-filter chips with the DCLogic filter in vanilla JS (empty
filter renders an honest empty line), the composite's 3-column list-row
design (DRAFT eyebrow in the tag slot, computed read time), and the
post view's block system (sans 17.5px body, serif crossheads, pill row,
gate-run footer, conditional next-rail). The seven sample posts, named
authors (Ravi Krishnan, Priya Nair), "18 posts · 6 people", and
invented gate ids stayed out. Schema gained optional ledger tag; the
real post is tagged argument. copy/status.txt (17 lines) and
copy/ledger.txt (13 lines) rewritten. All lints + 13 law tests green.
Surprise: none of the composites' hexes were missing from tokens.json,
but our Newsreader cut wraps the ledger H1 a word later than the
composite's hosted cut; max-w 14em (vs 15em) restores the exact break.
Next action: founder review of the DRAFT post treatment (return-list 3).

## 2026-08-20 · product pages fidelity rebuild (sessions, fork, gateway-cost, governance-replay)
The four product pages now mirror design/Product Pages.dc.html 1:1: the
composite is one tabbed template, so _Product.astro became its chrome
(own sticky header with the Pricing/Proof/Enterprise/Docs nav and the
tab row inside it, hero at clamp(38,5.4vw,60), inline metric cards with
the composite's 9px bordered MEASURED/ESTIMATED badges and the honest
unavailable chip, evidence line with a single /proof gate link, dark
CTA band ending the page, exactly like index.astro carries its own
chrome). Each tab's DCLogic dataset is carried verbatim per the
founder's fidelity ruling: the aspirational metrics (< 100 ms, < 90 s,
4,000 kills, 64 forks, −45%, 500 / 500), the G-1xx gate tags (linked to
/proof), the ks run/kill/resume terminal with the blinking ksBlink
cursor (CSS keyframes + reduced-motion fallback; the composite's only
animation), the fork timeline SVG, the 5-step gateway flow, and the
slate flight-recorder panel (Enterprise chip is a plain styled p, as
designed). Two fidelity fixes beyond markup: body leading-[normal]
(composite default; Tailwind's 1.5 had inflated pages 24-31px) and h1
max-w 17em vs the composite's 18em, because our self-hosted static
Newsreader renders ~2-5% narrower than the composite's hosted variable
cut and 18em unwraps the Gateway headline (same remedy the ledger
rebuild used, 14em vs 15em). Diff vs composite screenshots: <2% pixels,
all residual bands are serif glyph width. copy/product/*.txt rewritten
(15/14/19/16 lines). No hex missing from tokens.json. All lints + 13
law tests green. Surprise: one npm run build failed mid-session inside
another agent's legal page edit; it healed on retry.
Next action: none for these pages; founder eyeball at 1280.

## 2026-08-20 · /pricing rebuilt 1:1 from design/Pricing.dc.html
Rebuilt src/pages/pricing.astro standalone (own header, page ends at
the #partner band, like the composite and index.astro): hero, 4 tier
cards, meters table, calculator, FAQ, dark CTA. Calculator keeps its
working mechanics inside the composite's exact shell: server-rendered
defaults from the DCLogic formula, inline vanilla script, ESTIMATED
chip (now the composite's blush-on-inkLine chip, not the shared Badge
variant), and the NaN-proof unavailable state (verified in-browser:
pathological reading flips all 6 outputs to chips, readout "?", no
NaN; range inputs self-clamp so it is belt-and-braces). Fidelity
reverts of prior drift: meters copy back to the composite's 19x + "a
1.2 GB freeze taken every 5m adds about 41 MB" (gate-6/evidence links
dropped per the founder's verbatim-numbers ruling), Enterprise card
text slateSoft not parchment, panel labels termMuted, borders inkLine,
custom diamond range thumbs via is:global style (theme() tokens only).
FAQ is <details name="pricing-faq">: native exclusive accordion
matching DCLogic's single-open behavior, no JS. Same body
leading-[normal] fix as the product pages. Final diff vs composite at
1280: identical page height (3025), all bands align to the pixel;
residual diffs are Newsreader static-vs-variable glyph rendering in
the serif headlines (site-wide, same as index). Lints green (copy 354
lines incl. 16 for pricing), 13 law tests green. docs/compare
screenshots refreshed. Surprise: font-display:optional makes the
first cold paint measure 15px short until webfonts apply; converged
layout is exact.
Next action: none for this page; founder eyeball at 1280.

## 2026-08-20 — Fidelity rebuild: /customers and /grants
- Both pages rebuilt 1:1 from their composites (own chrome, no Site
  layout, verbatim content incl. numbers per the fidelity ruling).
- Customers ships the composite's DCLogic index<->report toggle as a
  vanilla script; carve-out applied: nonexistent third-party quotes and
  attributions render placeholder lines inside the exact blockquote
  visuals; "logo pending clearance" slots stay as designed.
- Grants keeps the working form (POST /api/grants, honeypot, range
  script, composite's error state reproduced); the composite's mock
  success panel is not simulated. TODO token #8A7A78 -> termMuted.
- Self-hosted Newsreader is ~3% narrower than the composite's Google
  variable font, so both H1s break a word later at 1280; spec values
  (max-w 16em/17em) kept. Design's slider thumb sits at 50% because the
  composite binds an invalid localized value; the working form shows
  the true $5,000 position.
- copy files updated (67 verbatim lines held); emdash lint clean.

## 2026-08-20 · fidelity rebuild: /manifesto + /careers (agent)
- Both pages rebuilt 1:1 from their composites, which carry their OWN
  chrome: manifesto = minimal header (logo + "Back to site") + one-line
  mono footer; careers = careers-specific nav (Manifesto/Proof/Grants/
  Open roles) and NO site footer (page ends on the ink CTA band). Site
  layout dropped on both, per the founder's design-is-the-spec ruling.
- Root causes of prior drift fixed: (1) Tailwind preflight line-height
  1.5 vs the composites' browser default -> body leading-[normal];
  (2) font-display:optional made non-preloaded faces stick on fallback
  at first paint -> preload the faces each page uses; (3) the sitewide
  STATIC Newsreader italic is ~3.5% wider than the composite's variable
  font (opsz axis), wrapping careers epigraph 2 -> self-hosted the
  variable italic latin subset (public/fonts/Newsreader-italic-var
  .woff2, page-scoped @font-face on /careers only); (4) careers role
  summary line inherits the UA <button> font (Arial) in the composite,
  which sets its wrap -> font-[Arial] on that line, commented.
- Careers roles ship as native <details> (first open, like DCLogic
  state open:0) + tiny inline accordion script (opening one closes the
  other); manifesto notify form keeps POST /api/subscribe + honeypot
  inside the exact shell, with the DCLogic "enter a valid address"
  note reproduced. Verified: built /careers full-page height 3946px ==
  composite; /manifesto 900px == composite; all probed section offsets
  within 3px. Non-token hex met: #8A7A78 (epigraph 1 meta) -> termMuted.
- copy files rewritten (manifesto 10, careers 18 verbatim lines); copy,
  emdash, link lints clean; vitest 13/13; docs/compare/built-*.png
  refreshed; design (8905) and built (8906) servers killed.

## 2026-08-20 · fidelity rebuild: docs shell + generated docs pages (agent)
- Docs shell rebuilt 1:1 from design/Docs.dc.html: docs-specific header
  (logo + mono "docs" + centered "Search the docs" ⌘K affordance +
  Pricing/Proof/Console →) added as Site.astro header="docs" variant;
  236px section nav with diamond markers and parchment active row; 72ch
  content column under breadcrumb + "last verified against {version}"
  blush badge (REAL v0.1.1 + release date 2026-07-31 from generated
  docs.json, never the composite's placeholder); 216px "On this page"
  TOC with claret first-item bar; feedback footer ("It worked"/"It
  failed" as mailto-free links to /contact).
- Root cause of the prior "bare column" build found: Astro drops the
  media attribute when bundling <style is:global media="print">, so the
  print rules (header/nav/aside display:none) applied on screen. Moved
  into @media print.
- Shiki's github-dark inline palette overridden inside .docs-prose
  (ink bg, monochrome parchment text) to match the composite terminals;
  .ks-copy restyled to composite (transparent, inkSoft border) with
  mechanics untouched (gate probe: 5/5 pre/copy on quickstart, cmd-K
  search returns quickstart for "resume", 8 results).
- Generated pages restyled toward composite archetypes, data sources
  unchanged: cli.astro (verb chips per Related treatment + dark usage
  blocks with mono kicker), api.astro (endpoint cards, claret method
  badge), troubleshooting.astro (symptom cards with diamond kicker,
  serif symptom, labeled meaning/action; blocked protocol in the blush
  "what you just proved" panel treatment). Markdown pages get composite
  typography via layout CSS; duplicate md h1s (quickstart/limits carry
  their own titles) hidden via .docs-prose h1 ~ h1.
- Step-rail treatment NOT applied to quickstart steps: the synced
  markdown cannot be retyped into the step markup without editing a
  generated data source; terminal + typography treatments carry it.
- Wired Footer's new docs pager (prev/next from nav order) through
  Site.astro pager prop. Non-token hex met: #6A6258 copy-button hover
  border -> taupe, commented. design/copy/docs.txt written (17 verbatim
  lines held). emdash/evidence/link lints clean; the 2 copy-lint
  violations on /support are another agent's in-flight page, verified
  pre-existing. docs/compare/built-docs.png refreshed; servers killed
  (8913 design, 8914 built, 8916 dist probe; 8915 belongs to another
  session and was left alone).

## 2026-08-20 · fidelity rebuild: Legal & Support, Auth & System States, Footer System
- Rebuilt src/pages/legal/{_Legal,terms,privacy,dpa,subprocessors,acceptable-use}.astro
  1:1 to the composite (244px doc nav, version chip + effective line, numbered serif
  sections, hairline lists, 3-col tables, PDF/history buttons, 212px toc rail).
  Fidelity ruling applied: draft notes removed, composite clauses restored verbatim
  (billing-incident history, AUP enforcement anecdote, DPA audit clause).
  Subprocessors keeps the honesty carve-out: only Azure/GitHub/Anthropic rows inside
  the composite's exact table design.
- support.astro: composite help-center (live filter over 8 real doc links, 3 path
  cards, SLA card verbatim, ticket form). New /api/support form spec in forms.js
  (kind+symptom required, evidence/session extras, contact table, honeypot).
- console.astro: composite sign-in visuals (GitHub + Google + email-link block)
  around the honest /.auth/me three-state shell; invite-pending card restyled to
  the composite card anatomy; banners not faked (carve-out a). 404/500 rebuilt to
  composite geometry; 500 ref card renders honest unavailable line (carve-out a).
- Footer.astro: five-band marketing footer (checkpoint dots border + tooltip,
  brand + install/subscribe cards, 4 link columns, random epigraph, socials +
  region + StatusChip pill, ink terminal line), docs variant (pager prop + bands
  3-5), console strip (Docs/Status/Support · Shortcuts ⌘K · v0.1.1). StatusChip
  gained a pill variant (default untouched; laws tests green).
- Surprise: Tailwind display utilities defeat the [hidden] attribute; added a
  global [hidden]{display:none!important} in Site.astro.
- TODO tokens: #8A8372 and #8A7A78 (both rendered as termMuted), #6A6258 (hover
  border, rendered as taupe). All lints + laws tests green; copy files updated.

## 2026-08-20 — The fidelity sweep: the design became the site
- Founder ruling: the built pages had drifted from the composites and
  the design is the spec, every detail. Process answer: render every
  composite in a real browser, screenshot both sides, LOOK, rebuild,
  re-look. Home rebuilt by hand first (terminal typewriter loop with
  kill-flash, fork draw-in, -45% count-up, partner strip, the
  composite's own footer); nine agents then swept every other page with
  the same loop, pixel-diffing their work (careers 3946px exact,
  pricing 3025px exact, offsets within 1-6px elsewhere).
- What survived fidelity, by constitution: Proof/Compatibility data
  stays generated (the composite's placeholder claims became a shell
  that real proof.json rows fill); status renders every live value
  honestly unavailable inside the exact layout; fabricated authors and
  quotes keep the design's placeholder treatments; forms keep working
  mechanics inside exact shells. Design-verbatim now includes the
  marketing numbers (founder overruled proof-only for depiction; F-6).
- Cross-agent conflicts resolved at integration: the global five-band
  footer restored on interior pages (every page-scoped agent dropped
  it; Footer System is itself a composite), region name honest in the
  live system line but design-verbatim in depiction rows, the last
  four composite colors promoted (32 named tokens, zero hex in src).
- Real bugs the sweep found: Astro drops media="print" on bundled
  styles (print rules were eating the docs chrome); Tailwind display
  utilities defeating [hidden]; a composite slider bound a localized
  string. New: support tickets POST to a real durable endpoint.
- Gates: w1 GREEN, w3 GREEN, w2 RED only on its home-footer probes
  (home follows its composite, which has no status system): one-line
  amendment in BLOCKED.md. Founder flags F-1..F-6 in BACKLOG.
