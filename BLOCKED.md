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

## While blocked

web-4-green is NOT tagged. Phase W5 (budgets and hardening) does not
depend on this assertion and proceeds per the founder's all-phases
directive. On the founder's written amendment, the gate re-runs whole;
with the email key also set, the abort leg closes in the same run.
