# Phase W0 - Scaffold and pipeline

HYPOTHESIS: the pipeline is real end to end. A trivial commit reaches
the staging URL automatically; the production deploy is manual-approval
only; infra scripts re-run idempotently.

## What was built

- Astro 5 + MDX + Tailwind 3, configured exclusively from
  design/tokens.json (extracted by scripts/extract-tokens.mjs: 12
  semantic colors, 22 extended hexes parked for W1 resolution, type
  scale, radii, shadows). No hex value exists outside tokens.json.
- 14 self-hosted latin woff2 subsets (Newsreader, Inter, JetBrains
  Mono) via scripts/fetch-fonts.sh; no third-party CDN at runtime.
- Holding page (one paragraph, noindex) on the SWA default hostname:
  https://icy-wave-0eefe5403.7.azurestaticapps.net
- Pipeline: PR -> SWA preview environment; push to main -> named
  'staging' environment automatically; production slot ONLY via
  workflow_dispatch. Branch protection requires the build check.
- Azure estate recorded in ADR-W1; identity is the ks operator,
  Owner on the two KS groups only; deployment token piped into
  GitHub secrets without ever entering the conversation.

## Gate W0 - normal run (raw output, exit 0)

```
=== GATE W0 (normal mode) 2026-08-19T15:53:04Z ===
--- 1. trivial commit reaches staging automatically ---
pushed probe 2c38400ac77ced4d to main; polling staging
ASSERT PASS: staging serves the probe with no human action
--- 2. production is manual-only ---
ASSERT PASS: workflow graph: production job exists only under workflow_dispatch
ASSERT PASS: production untouched by the main push (probe absent there)
--- 3. infra idempotency ---
ASSERT PASS: infra script exits 0 twice
ASSERT PASS: still exactly one SWA after re-runs (n=1)
ASSERT PASS: second run reports exists, creates nothing
GATE W0: GREEN - the pipeline is real end to end
```

## Gate W0 - sabotage run (raw output, exit 0)

```
=== GATE W0 (--sabotage mode) 2026-08-19T15:54:54Z ===
--- sabotage: a broken page must be unmergeable ---
sabotage PR #1 opened; waiting for the build check to fail
build check concluded: fail
ASSERT PASS: broken build fails CI
ASSERT PASS: merge state is BLOCKED
ASSERT PASS: non-admin merge attempt refused
GATE W0 SABOTAGE: GREEN - a broken commit cannot reach main
Deleted branch w0-sabotage (was f75ed45).
```

## Notes

- The probe file public/pipeline-probe.txt stays in the tree; each
  gate run overwrites it. It is the pipeline's heartbeat, not litter.
- Direct pushes to main by the repo admin bypass the required check
  (enforce_admins=false, deliberate: the builder pushes green
  sub-steps directly; PRs are the protected path). The sabotage run
  proves the PR path blocks.
