# BLOCKED — gate-w4's OAuth assertion cannot pass on SWA, and only the founder amends gates

Written 2026-08-20 during Phase W4. Everything else in the phase is done
and proven; nothing in gates/ was modified.

## The state of gate W4

19 of 20 assertions pass against staging (raw log in docs/phase-w4.md):
every form writes a durable row before email and survives a dead email
step live; malformed submits store nothing; the honeypot pretends success
and stores nothing; the rate limiter returns 429 on the burst; the
console shell renders only honest states; sabotage (broken Table
connection) fails on durability with no false success. The email-arrival
leg ABORTS with exit-75 semantics: no provider key exists, so that trial
cannot be held. It runs the day KS_EMAIL_KEY is set.

## The one failing assertion, and why it can never pass

The gate asserts the FIRST redirect of /.auth/login/github contains
github.com:

    LOC=$(curl -s -o /dev/null -w '%{redirect_url}' "$BASE/.auth/login/github")
    echo "$LOC" | grep -q 'github.com'

Azure Static Web Apps routes every social login through its own identity
broker first. Measured chain, 2026-08-20:

    hop 1: https://identity.7.azurestaticapps.net/.redirect/github?...
    hop 2: https://identity.7.azurestaticapps.net/.auth/login/github?...
    hop 3: https://github.com/login/oauth/authorize?...
    curl -L url_effective: https://github.com/login?client_id=Ov23li...

OAuth is wired and working; the assertion just watches hop 1 of a
three-hop platform mechanism. This is the inherited rule-15 defect
class: an assertion unsatisfiable under the platform's own documented
behavior is a transcription error in the gate, not a product failure.

## Proposed amendment (one line, header bump to v2)

Replace the two lines above with a chain-following check:

    LOC=$(curl -s -o /dev/null -L --max-redirs 5 -w '%{url_effective}' "$BASE/.auth/login/github")
    echo "$LOC" | grep -q '^https://github.com/' \
      && pass "/.auth/login/github chain lands on github.com" \
      || fail "auth chain landed on: ${LOC:-nowhere}"

Stricter than the original (asserts the landing host, not a substring
anywhere in a URL), and satisfiable.

## Second blocked assertion set: the sabotage's own precondition

The sabotage breaks KS_LEADS_CONN and sleeps 20 s. Measured on
2026-08-20: SWA app-setting changes take 7 to 10 MINUTES to reach the
running worker. The sabotage judged the system before its own sabotage
was in effect, so its three failures are a trial that could not be held
(rule-14 class), not a falsification. Live evidence that the mechanism
works once propagation lands: during the restore window, submissions
returned /sorry?why=storage and stored NOTHING (verified by table
query); durability failure was loud and no email was implied.

Amendment options for the sabotage, founder's choice:
1. RECOMMENDED: change the vector: delete the leads table instead of
   breaking the connection (takes effect immediately, no propagation),
   assert /sorry?why=storage + no false success, then recreate the
   table. Header bump to v2.
2. Keep the vector, replace sleep 20 with poll-until-flipped (cap 15
   min): submit probes until one returns why=storage, then run the
   assertions.

## Gate W5: three amendments, same rule-15 family (all evidence measured)

1. The header probe uses HEAD (`curl -fsSI`); SWA attaches globalHeaders
   to GET only. Measured: GET serves the full set (CSP with 9 script
   hashes and no unsafe-inline for scripts, HSTS max-age=31536000
   WITHOUT preload beating the platform default, frame-ancestors none,
   nosniff, referrer-policy). Amendment: `curl -s -D- -o /dev/null`.
2. gates/gate-w5-audit.mjs crashes in the axe leg: AxeBuilder requires a
   page from browser.newContext(), not browser.newPage(). Two-line fix
   in the audit script (part of the gate, so founder authority).
3. The audit measures `astro preview`, which serves UNCOMPRESSED HTML.
   Production serves brotli: pricing is 70,042 bytes raw, 7,255 encoded.
   Measured LCP: localhost 1,955 ms (budget fail by 155 ms), staging
   914 ms with performance 100. Amendment: the gate exports
   GATE_BASE=$STAGING to the audit leg so budgets measure the transport
   users get. Local scores stay in the log as a canary.

With the three amendments applied and the deployed contrast fixes, every
W5 measurement is green on the real host (home 100/100 local even
uncompressed).

## Gate W2, one amendment after the fidelity sweep

The founder's fidelity ruling (2026-08-20) rebuilt every page 1:1 from
its composite. Home's composite carries its OWN footer (four columns,
no status system), so gate-w2's footer-honesty probes, which read
dist/index.html, now fail on a page that is correct by ruling. The
five-band footer with the unavailable chip and system line lives on
every interior marketing page (verified: /pricing/ carries
data-status="unavailable" and the all-unavailable system line).
Amendment: point section 3's three greps at dist/pricing/index.html.

## While blocked

web-4-green is NOT tagged. Phase W5 (budgets and hardening) does not
depend on this assertion and proceeds per the founder's all-phases
directive. On the founder's written amendment, the gate re-runs whole;
with the email key also set, the abort leg closes in the same run.
