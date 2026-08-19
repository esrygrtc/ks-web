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
