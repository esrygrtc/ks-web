# Cutover pack: the exact DNS records (founder sets these at the registrar)

Target Static Web App: `ks-web`, default hostname
`icy-wave-0eefe5403.7.azurestaticapps.net`.

## Records

| Host | Type | Value |
|---|---|---|
| `www` | CNAME | `icy-wave-0eefe5403.7.azurestaticapps.net` |
| `@` (apex) | ALIAS / ANAME (if the registrar supports it) | `icy-wave-0eefe5403.7.azurestaticapps.net` |

If the registrar has NO ALIAS/ANAME at the apex: the supported route is
delegating DNS to Azure DNS (a zone is ~$0.50/mo, a new-resource
approval) or using the registrar's HTTP redirect from apex to www. TXT
validation records: Azure will show a per-hostname TXT `_dnsauth` value
when `infra/add-domains.sh` runs; add it when prompted.

## After DNS propagates (the order matters)

1. `bash infra/add-domains.sh` (as ks; script below adds both hostnames
   and prints any TXT validation Azure asks for)
2. Deploy production (founder's manual dispatch of the ci workflow)
3. `bash gates/gate-w6.sh` and `bash gates/gate-w6.sh --sabotage`
4. Uptime: approve ~$2-5/mo, run `infra/create-uptime.sh <founder-email>`,
   test-fire the alert once, paste evidence into docs/phase-w6.md
5. Email for keepstate.ai (BACKLOG W-1) must exist BEFORE the site is
   public: security@ is printed on the security page
