# KEEPSTATE-WEB — Phase Plan

## Phase W0 — Scaffold and pipeline (deploy a coin before a fortune)
Build: Astro scaffold; tokens.json extracted from design/ guidelines and
wired into Tailwind; fonts self-hosted; repo structure (src/content for
docs, ledger, changelog, legal); GitHub Actions -> Azure Static Web App
(Standard) with per-PR staging; infra/ scripts + ADR-W1 recording every
resource created; a one-paragraph holding page deploys to the SWA
default hostname.
Gate W0: HYPOTHESIS: the pipeline is real end to end. A trivial commit
reaches the staging URL automatically; the production deploy is
manual-approval only; infra scripts re-run idempotently. Sabotage: break
the build (syntax error in a page); CI must block the merge.

## Phase W1 — The component sheet (design system becomes code)
Build: every component from the Step 2 sheet as Astro/island components
driven only by tokens.json: buttons, forms, mono tables, terminal block
with copy, diamond timeline, metric cards with MEASURED/ESTIMATED
badges, status pills, budget bars, toasts, modals with type-to-confirm,
banners, tabs, cmd-K palette, skeletons, empty states (each teaching a
command), the unavailable chip. A /design-system route renders all
components in all states, including every unavailable state.
Gate W1: HYPOTHESIS: the system enforces its own laws. Component tests:
metric card with null data renders "unavailable" and cannot render 0;
status chip without feed renders UNAVAILABLE; badges required by prop
types. Visual page screenshotted for the phase doc. Sabotage: feed a
metric component null with the guard disabled; the test must fail.

## Phase W2 — Marketing pages (parity with the design, copy verbatim)
Build: Home, four Product pages, Pricing (with calculator island,
outputs ESTIMATED), Proof (generated via scripts/sync-claims from the
product repo's claims.md + gate tags), Compatibility (same generator),
Customers (pilot-report template with placeholder cards marked as
placeholders), Enterprise, Security, Grants (form), Careers (epigraphs
as designed), Manifesto, About, Press, Contact, the global footer with
all three variants and the system line consuming a status feed that
currently returns unavailable-by-honesty.
Gate W2: HYPOTHESIS: the public site matches its spec and its laws.
House-style lints green (em-dash, evidence, links, copy fidelity);
sync-claims hash check green; footer renders unavailable status
honestly; sitemap and OG images generated; robots.txt sane. Sabotage:
insert an em dash and an evidence-free claim row in fixtures; both
lints must fail.

## Phase W3 — Docs and content systems
Build: docs three-column layout, Pagefind cmd-K, Quickstart page from
the product repo's QUICKSTART.md (synced, not retyped), Concepts,
Guides, CLI and API reference templates filled from product docs,
Limits, Troubleshooting, FAQ; The Ledger blog index + first post
("Counting the OOMs of agent-hours", drafted from the manifesto
material for founder review, marked DRAFT until approved); changelog
wired to render the product repo's tag notes.
Gate W3: HYPOTHESIS: a stranger can navigate from landing to a runnable
quickstart. Link lint zero broken; search returns the quickstart for
"resume"; every code block has a working copy button (tested); synced
content hash-checked against sources. Sabotage: corrupt the quickstart
sync hash; the gate must fail.

## Phase W4 — Forms, functions, and the early-access console shell
Build: SWA managed Functions for design-partner intake, grants
applications, and subscribe; each writes to an Azure Table FIRST, then
emails; honeypot + rate limit; success and error states per voice laws
("Our fault, and our ledger saw it" style honesty). Console shell at
app.keepstate.ai path or subdomain: GitHub OAuth sign-in (via SWA
auth), waitlist state, invite-pending state, zero fake data.
Gate W4: HYPOTHESIS: no lead can be lost and no state lies. Submit each
form on staging: row exists in Table before email sends; email arrives;
malformed submits rejected politely; killing the email step still
preserves the row (run it). OAuth round-trip works; console shell
renders only honest states. Sabotage: disable the Table write; the
gate must fail on durability, not on email.

## Phase W5 — Performance, accessibility, and hardening
Build: image pipeline (AVIF/WebP, explicit dimensions), font subsetting
verified, security headers (CSP without unsafe-inline, HSTS no
preload, frame-ancestors none, referrer-policy), 404 and 500 pages as
designed, prefers-reduced-motion audit, print stylesheet for docs.
Gate W5: HYPOTHESIS: fast for everyone, by budget not by vibe.
Lighthouse CI budgets on key pages: Performance >= 95 (marketing),
>= 90 (docs), Accessibility >= 95 with axe zero critical; LCP < 1.8s,
CLS < 0.1 on throttled mobile; headers verified by curl assertions.
Sabotage: inject a 2 MB unoptimized hero image on a fixture branch;
the budget must fail.

## Phase W6 — Cutover, load, rollback (launch day is a gate)
Build: custom domains keepstate.ai + www on SWA with managed TLS
(human sets DNS per your exact records); cache-control policy (long
immutable for assets, short for HTML); k6 load script; uptime ping
(Azure Monitor availability test) alerting the founder's email;
scripts/rollback.sh proven.
Gate W6: HYPOTHESIS: launch is boring. DNS + TLS green on apex and www;
k6: 500 concurrent virtual users for 10 minutes against production,
p95 TTFB < 300 ms, error rate 0 (static pages) with form endpoints
excluded from load; rollback REHEARSED: deploy previous artifact,
verify, re-deploy current, all under 10 minutes, timed and logged;
uptime alert test-fired once. Sabotage: point rollback at a
nonexistent artifact; it must abort loudly, exit 75 semantics, never
half-deploy.

## Post-launch standing law
Every merge to main passes W-lints and budget checks; production
deploys are manual-approval; JOURNAL.md and BACKLOG.md continue; the
Proof and Compatibility pages update ONLY via sync-claims when the
product repo tags change.
