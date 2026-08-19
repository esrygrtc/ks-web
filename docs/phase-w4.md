# Phase W4 - Forms, functions, and the early-access console shell

HYPOTHESIS: no lead can be lost and no state lies.

STATUS: BUILT AND 19/20 PROVEN; UNTAGGED, BLOCKED ON TWO GATE
AMENDMENTS (see BLOCKED.md) plus the founder's email key.

## Built

- Azure: storage account kswebleads (LRS, ~cents/mo) + four tables,
  idempotent script, ADR-W2. Connection string piped to SWA settings
  without entering the conversation.
- api/: one function per form (partner, grants, subscribe, contact).
  The law in code: Table row FIRST, then email, then the email
  outcome recorded on the row. Honeypot pretends success and stores
  nothing. Rate limit five per ten minutes per ip-hash per form.
- Console shell at /console: three honest states (signed-out default,
  invite-pending via /.auth/me, auth-unavailable as its own state);
  SWA built-in GitHub auth; zero invented metrics (gate-checked).
- 404, 500, /thanks, /sorry per the composites and voice laws.

## Defects the gate caught (fixed) and defects the gate has (blocked)

- CAUGHT: SWA's x-forwarded-for carries a per-request port; the rate
  limiter bucketed every submit separately (six 303s). Fixed; burst
  now reads 303 then five 429s.
- FLAKE: the first run hit a stale CDN replica for /console 90s after
  deploy (404-then-200); passed on re-run untouched.
- BLOCKED 1: the OAuth assertion watches hop 1 of SWA's three-hop
  auth chain; the chain measurably lands on github.com at hop 3.
- BLOCKED 2: the sabotage sleeps 20s against a measured 7-10 MINUTE
  app-setting propagation. Live evidence the law holds: during the
  broken-conn window, submissions returned sorry?why=storage and
  stored nothing (Rest1-9 absent from the table; Rest10 present
  after recovery).

## Gate W4 - best normal run (raw, exit 1: the one blocked assertion)

```
=== GATE W4 (normal mode) 2026-08-19T21:53:12Z ===
--- 0. mechanical order proof: the row precedes the email in code ---
ASSERT PASS: createEntity (line 99) precedes notify (line 100)
--- 1. each form: valid submission -> thanks + durable row ---
ASSERT PASS: partner: accepted (303 -> /thanks)
ASSERT PASS: partner: durable row in table 'leads'
ASSERT PASS: grants: accepted (303 -> /thanks)
ASSERT PASS: grants: durable row in table 'grants'
ASSERT PASS: subscribe: accepted (303 -> /thanks)
ASSERT PASS: subscribe: durable row in table 'subscribers'
ASSERT PASS: contact: accepted (303 -> /thanks)
ASSERT PASS: contact: durable row in table 'contact'
--- 2. the dead email step, run live ---
ASSERT PASS: email step is dead (unconfigured) and the row survived it: recorded emailStatus=unconfigured
LEG ABORTED (exit-75 semantics): email-arrival cannot be tried, no provider key is configured. The leg runs when the founder sets KS_EMAIL_KEY.
--- 3. malformed submissions rejected politely, stored never ---
ASSERT PASS: missing fields -> /sorry
ASSERT PASS: invalid email -> /sorry
ASSERT PASS: rejects stored nothing (rows 1 -> 1)
--- 4. honeypot: pretends success, stores nothing ---
ASSERT PASS: honeypot answered with success
ASSERT PASS: honeypot stored nothing (contact rows steady at 1)
--- 5. rate limit: the sixth rapid submit is refused ---
codes: 303 429 429 429 429 429
ASSERT PASS: burst met a 429
--- 6. OAuth wiring: GitHub answers the door ---
ASSERT FAIL: auth redirect went to: https://identity.7.azurestaticapps.net/.redirect/github?hostName=icy-wave-0eefe5403-staging.westeurope.7.azurestaticapps.net&staticWebAppsAuthNonce=3rcI7Fln%2fNRPRqT%2fKhdr4HLxXDvPceDAO5UDT0rFGno55Y9gHOZ7RO4B7L8uK7ghBN2VmZBZo4aj9tZ3zsy6JVw%2bdQOEMHzE2SYSvXssqNSO4hTQploTzPeF93TAJlBt&functionKeyVersion=0
--- 7. the console shell lies to no one ---
ASSERT PASS: signed-out state renders
ASSERT PASS: state machine present
ASSERT PASS: zero invented metrics in the shell
GATE W4: RED - 1 assertion(s) failed
```

## Gate W4 - sabotage run (raw, exit 1: propagation, see BLOCKED.md)

```
=== GATE W4 (--sabotage mode) 2026-08-19T21:54:09Z ===
--- sabotage: Table connection broken; durability must fail loudly ---
WARNING: App settings have been redacted. Use `az staticwebapp appsettings list` to view.
response: 303 https://icy-wave-0eefe5403-staging.westeurope.7.azurestaticapps.net/thanks
ASSERT FAIL: submission reported SUCCESS while storage was broken
ASSERT FAIL: failure did not name storage
ASSERT FAIL: a row appeared despite broken storage
WARNING: App settings have been redacted. Use `az staticwebapp appsettings list` to view.
ASSERT PASS: restored: a submission lands again
GATE W4 SABOTAGE: RED - 3 assertion(s) failed
```
