# keepstate-web — Architecture Decision Records

## ADR-W1 — Day-zero Azure estate (2026-08-19)

**Status:** accepted.

**Every Azure resource this project owns, and nothing else:**

| Resource | Name | Group | Tier / cost | Created by |
|---|---|---|---|---|
| Resource group | `keepstate-web-rg` | — | $0 | admin, 2026-08-19 |
| Resource group | `keepstate-rg` | — | $0 | admin, 2026-08-19 |
| Static Web App | `ks-web` | `keepstate-web-rg` | Standard, ~$9/mo | ks, `infra/create-swa.sh` |

Default hostname: `icy-wave-0eefe5403.7.azurestaticapps.net`.

**Identity model.** All operations run as `ks@devplaybliss.onmicrosoft.com`,
whose only rights are Owner on the two groups above. A mistake outside
KS scope is structurally impossible, not merely forbidden. `ks` cannot
create new resource groups; that is an admin moment by design.

**Naming law (founder, 2026-08-19).** Azure resource names never contain
"keepstate"; the abbreviation `ks` is used everywhere. The two resource
groups pre-date the rule and cannot be renamed (Azure has no RG rename)
nor recreated by `ks` (no subscription-level right). Recorded as a
standing exception until the founder chooses to recreate them as admin.

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
