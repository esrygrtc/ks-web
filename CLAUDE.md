# KEEPSTATE-WEB — Constitution

## Mission
Build and launch keepstate.ai on Azure from the completed Claude Design
system in design/. The site must serve hundreds of concurrent visitors
smoothly with nobody watching it, which is achieved by one architectural
vow: static-first. Marketing and docs are prebuilt files on a CDN edge;
the only compute in the hot path is a handful of small functions for
forms. This repo inherits the product's constitution: gates are law,
sabotage tests prove the gates, journals carry memory, ADRs precede
architecture, and no claim outlives its evidence.

## The postcard (why day zero looks like this)
Written backwards from month six: traffic is boring because pages are
static; publishing is a pull request because content is markdown in git;
redesigns are diffs because tokens live in one file; quality cannot
regress because gates run in CI on every merge; trust is automated
because the Proof page is generated, the status chip cannot fake green,
and rollback was rehearsed on launch day.

## Settled stack (do not relitigate)
- Framework: Astro + MDX. Content collections for docs, blog ("The
  Ledger"), changelog, legal. Interactive islands only where the design
  demands them (pricing calculator, cmd-K search, copy buttons).
- Styling: Tailwind, configured EXCLUSIVELY from design/tokens: one
  tokens.json extracted from the Claude Design guidelines (colors, type
  scale, spacing, radii, shadows). No hex value may appear outside it.
- Fonts: Newsreader (or Source Serif 4), Inter, JetBrains Mono,
  SELF-HOSTED woff2 subsets. No third-party font or script CDNs.
- Search: Pagefind (static, built at compile time) behind the cmd-K UI.
- Hosting: Azure Static Web Apps, Standard tier, with its managed
  Functions for form endpoints. GitHub Actions CI/CD with SWA's
  per-PR staging environments. Region nearest the founder's users.
- Forms backend: SWA managed Functions writing every submission to an
  Azure Table (leads are durable BEFORE any email is attempted) and then
  notifying via email. A lost lead is a lost session; we do not lose
  sessions.
- Analytics: none on day zero. No trackers, no cookies, no banner.
- Infra as code: every az command that creates or changes a resource is
  committed as a script under infra/ with an ADR. The site must be
  reproducible from the repo alone.

## Scope fences (hard)
- The console ships as an honest early-access shell: login page design,
  waitlist and design-partner intake, and a "your invite is pending"
  state. NO live console, NO invented metrics, NO mock dashboards with
  numbers. Fake data violates UI Law 2 and is treated as a defect.
- No self-hosting content anywhere, per founder decision.
- No CMS, no databases beyond the leads Table, no A/B tools, no chat
  widgets, no third-party embeds on day zero.
- Product repo is read-only input (claims.md, gate tags, quickstart);
  this repo never modifies it.

## UI Laws (from the design brief, now enforced in code)
1. Missing data renders "unavailable", never zero. Component tests
   assert the unavailable state exists and that no metric component can
   render 0 from a null feed.
2. Every rendered number carries a MEASURED or ESTIMATED badge or an
   evidence link. Calculator outputs are ESTIMATED.
3. The status chip has three states (operational, incident,
   unavailable) and its default with no feed is UNAVAILABLE. A unit
   test asserts green is impossible without live data.
4. The Proof page is GENERATED from the product repo's claims.md by
   scripts/sync-claims; hand-editing its output is forbidden and CI
   fails if the rendered page hash disagrees with the source.

## House-style lints (CI, blocking)
- Em-dash lint: the characters — and – used as em dashes fail the
  build across all content and UI strings (en dash allowed in numeric
  ranges only).
- Evidence lint: any line in Proof or Compatibility content missing an
  evidence tag fails.
- Link lint: zero broken internal links, zero orphan pages.
- Copy fidelity: pages whose copy was specified verbatim in the design
  briefs are diffed against design/copy sources; drift fails.

## The law of gates (inherited, web-flavored)
Gates live in gates/, written once at the phase the plan names, never
edited after creation; amendments require human authority and a header
bump. Every gate: hypothesis line, timeout, cleanup, and a --sabotage
mode that must fail correctly. Assertions test the site, never taste:
budgets, states, links, headers, laws. Raw output of gate and sabotage
into docs/phase-N.md; green gates get git tags (web-N-green).

## Tripwires (stop and ask the human)
- Creating ANY Azure resource: disclose the resource, tier, and monthly
  cost estimate first; proceed only on approval. Expected day-zero
  bill: SWA Standard (~$9/mo) + Table storage (cents). Anything beyond
  that list is a conversation.
- DNS changes at the registrar (human performs them; you provide exact
  records and verify propagation).
- Anything requiring secrets: deployment tokens and email API keys are
  set by the human in GitHub Actions secrets and SWA config; secrets
  never appear in the repo, logs, or this conversation.
- HSTS preload submission: one-way like a license; prepare the header,
  flag the decision, do not submit.

## Builder hygiene
JOURNAL.md per session (decisions, versions, surprises, next action).
Rehydrate each session from CLAUDE.md, WEBPLAN.md, JOURNAL.md, and the
latest docs/phase-*. Long jobs run detached. BLOCKED.md protocol after
three distinct failed hypotheses. Commit per green sub-step.
