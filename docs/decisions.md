# keepstate-web — Architecture Decision Records

## ADR-W1 — Day-zero Azure estate (2026-08-19)

**Status:** accepted.

**Every Azure resource this project owns, and nothing else:**

| Resource | Name | Group | Tier / cost | Created by |
|---|---|---|---|---|
| Resource group | `ks-web-rg` | — | $0 | admin, 2026-08-19 |
| Resource group | `ks-rg` | — | $0 | admin, 2026-08-19 |
| Static Web App | `ks-web` | `ks-web-rg` | Standard, ~$9/mo | ks, `infra/create-swa.sh` |

Default hostname: `icy-wave-0eefe5403.7.azurestaticapps.net`.

**Identity model.** All operations run as `ks@devplaybliss.onmicrosoft.com`,
whose only rights are Owner on the two groups above. A mistake outside
KS scope is structurally impossible, not merely forbidden. `ks` cannot
create new resource groups; that is an admin moment by design.

**Naming law (founder, 2026-08-19).** Azure resource names never contain
"keepstate"; the abbreviation `ks` is used everywhere. The original
`keepstate-*` groups pre-dated the rule; the founder logged in as admin
the same day and the estate was migrated: new `ks-web-rg`/`ks-rg`
created, the SWA moved (zero downtime, hostname unchanged), Owner
re-granted to ks on the new groups only, old groups deleted. The
exception no longer exists; the naming law now holds everywhere.

**Why SWA Standard, not Free.** Custom OAuth for the W4 console shell,
the SLA, and per-PR staging environments are Standard features. ~$9/mo
is the constitution's expected day-zero bill.

**Why the deployment token lives only in GitHub secrets.** Set by
piping `az staticwebapp secrets list` straight into `gh secret set`;
it never appeared in the conversation, the repo, or logs. Rotation is
one command (`az staticwebapp secrets reset-api-key`) plus re-piping.

**Pipeline shape (gate W0's subject).** PR opened -> SWA preview
environment; merge to main -> named `staging` environment,
automatically; production slot deploys ONLY from `workflow_dispatch`.
There is no automatic path to production, which makes the manual
approval a property of the workflow graph rather than a policy.

## ADR-W2 — The leads path: durable before delivered (2026-08-20)

**Status:** accepted, Phase W4.

**Resources added** (the second half of the constitution's expected
day-zero bill):

| Resource | Name | Group | Tier / cost | Created by |
|---|---|---|---|---|
| Storage account | `kswebleads` | `ks-web-rg` | Standard_LRS, ~cents/mo | ks, `infra/create-storage.sh` |
| Tables | `leads`, `grants`, `subscribers`, `contact` | in `kswebleads` | included | same script |

**The law of the leads path.** Every form handler writes its Table row
FIRST, then attempts email, then records the email outcome on the row
(`sent`, `failed:<reason>`, or `unconfigured`). Email failure changes
nothing the submitter sees: a lost lead is a lost session, and email is
a notification, never a dependency. The honeypot pretends success and
stores nothing: a bot is not a lead. Rate limiting is per IP-hash per
form, five per ten minutes, and the 429 says the earlier submissions
are safe.

**Email provider is the founder's moment.** The notify step speaks a
Resend-compatible HTTP API and reads KS_EMAIL_KEY / KS_EMAIL_TO /
KS_EMAIL_FROM / KS_EMAIL_API from SWA settings, all unset today. Until
the founder sets them, emailStatus records `unconfigured` and gate W4's
email-arrival leg aborts with exit-75 semantics: a trial that cannot be
held, not a falsified claim.

**Auth is SWA's built-in GitHub provider.** No custom registration, no
client secret, no cost: /.auth/login/github ships with Standard. The
console shell reads /.auth/me client-side and renders three honest
states (signed-out, invite-pending, auth-unavailable).

**The connection string** went from `az storage account
show-connection-string` straight into SWA app settings without entering
the conversation, the repo, or logs, same discipline as the deployment
token.
