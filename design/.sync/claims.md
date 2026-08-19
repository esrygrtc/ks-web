# What KeepState claims, and the gate that proves it

The standing invariant: **no claim outlives its gate.** Every row below cites
a green tag in this repository. A claim whose gate is removed, or whose gate
never existed, is removed from this file — not softened, not footnoted. It
runs forward too: no claim precedes its gate.

Second rule, learned in Phase 7: **when behavior splits by third party, the
claim splits with it.** A sentence true of one agent and not another is two
sentences, each carrying its own evidence.

Gate 7 machine-checks this file: every row must cite a tag that exists in
`git tag`, and a row citing a missing tag fails the gate.

## Proven

| Claim | Proven by | The evidence |
|---|---|---|
| A microVM's memory survives a hard kill of its VMM | `gate-1-green` | Nonce `f65f7add…` continued 2 → 3,4,5 across `kill -9`; a fresh boot fails the same assertions |
| A daemon can carry sessions across kill-and-resume | `gate-2a-green` | Gate run twice back to back from clean state; sabotage (fresh boot) correctly failed |
| A checkpoint is a portable object, restorable elsewhere | `gate-2b-green` | Data dir gutted; a second ksd revived the session from chunks + manifest alone |
| Checkpoint publishing is crash-consistent | `gate-2b-green` | Crash injected mid-publish; previous checkpoint byte-identical, no torn manifest visible |
| A corrupt checkpoint refuses to restore rather than booting garbage | `gate-2b-green` | One flipped byte → restore refused, no firecracker started |
| An agent survives kill-and-resume through the gateway with reconciled ledgers | `gate-3-green` | Guest seq and host head converged at 5; `ledger.reconciled` recorded a gap of exactly 1 |
| Billed at most once, gateway-enforced, regardless of client behavior | `gate-3-green`, `gate-7-green` | No request hash appears twice in billed spend; a completed response is retained for the interrupted call whether or not the client returns for it. |
| An interrupted call is transparently absorbed on resume — **Claude Code** | `gate-3-green` | Retry served from store citing `original_seq=4`; 31,486 tokens excluded from spend |
| The whole demo runs unattended in one command | `gate-4-green` | `ks demo --kill-at 3m --headless` exit 0; measured downtime 25.2 s; doctor clean at end |
| A killed agent resumes with its work intact | `gate-4-green` | The microVM **and** ksd killed together; specimen returned and finished the fixture task |
| One checkpoint forks into branches that diverge | `gate-5-green` | Three branches, three disks, three lineage chains; a file written in A absent from B and C |
| Steering is a gateway concern; guests are never touched | `gate-5-green` | Pre-steer bodies byte-identical (`6d7c898a…`) across branches; only the steer differed |
| Durability is a rate, not an anecdote | `gate-6-green` | 25/25 fresh kill-and-resume cycles, **Wilson 95% CI [86.7%, 100.0%]** |
| Checkpoints hours old still wake | `gate-6-green` | A ~14.5 h-old preserved checkpoint woken in 14.3 s: `COUNT=63` while its living twin read 4841 |
| Repeated checkpointing does not grow storage linearly | `gate-6-green` | 82 checkpoints: 4,233 MiB actual vs 80,952 MiB naive — **19.1× dedup** |
| The daemons do not leak memory under sustained load | `gate-6-green` | 7 h soak, 82 checkpoints: ksd **+0 MiB**, ksgw **+0 MiB** peak RSS growth |

*Gate 7 re-proves the billing row against a second, differently-behaved client
(B3 v2 iv), and adds generality — a second agent and a second machine. All
three citations join this table the moment `gate-7-green` exists, not before. Gate 7 machine-checks that no row cites a tag that does not exist.*

## Deliberately not claimed

These are the sentences a reader might expect and will not find. They have no
gate, so they are written as prose, not as rows — a row in this document is a
promise, and a promise needs a tag.

- **"Runs on a different provider."** Rewritten to *fresh host, fresh daemon*.
  Every gate to date runs against one provider; a second host is not a second
  provider. Earning it needs a second provider path through ksgw, with a gate
  that freezes and resumes an agent on it.
- **"Production-ready" / "scales."** The bench is one Mac Mini, and gate 6
  measured one seven-hour soak, not a fleet. Earning it needs multi-host
  operation with a gate that survives host loss, not merely process loss.
- **"Zero downtime."** Measured downtime is 14-25 s, dominated by chunk
  reassembly (ADR-008 roadmap). Earning it needs lazy paging or parallel
  reassembly, with the breakdown re-measured.
- **"An interrupted call is transparently absorbed on resume" — for aider.**
  True of Claude Code and gated (`gate-3-green`). For aider it is reported as
  data, not promised. Across gate 7's runs the gateway held the response every
  time and the client returned for it most of the time — **door held 4 of 4,
  walked through 3 of 4** (runs 1, 3 and 4 retried, replaying 2,631, 2,635 and
  2,635 tokens free; run 2 did not, leaving the response retained on disk,
  2,556 bytes). The
  gateway can hold the door open forever; walking back through it belongs to
  the client. The per-run table is the first entry of the **public
  compatibility matrix** — per-agent, evidence-linked, updated only by gate
  runs, never by hand:

  | Agent | Interrupted call absorbed on resume | Evidence |
  |---|---|---|
  | Claude Code | **claimed** | `gate-3-green` |
  | aider 0.86.2 | **not claimed** — door held 4 of 4, walked through 3 of 4 | `gate-7-green` (runs tabulated in `docs/phase-7.md`) |
- **"Any agent works out of the box."** One second agent is evidence of
  generality, not proof of universality. Earning it needs more agents behind
  the same gate, each with its config surface recorded as an ADR.
- **A resume success percentage beyond what the sample carries.** 25/25 is
  100% observed, but 25 trials cannot support more than 86.7% at 95%
  confidence. The claim moves only when the interval does.

## The rule this file exists to enforce

Three times in this project a measurement contradicted a belief: the soak
found a connection leak twenty-five clean cycles could not see; our own
cleanup destroyed an artifact a ruling had protected; and a gate passed an
assertion on empty evidence while the system under test was healthy. Each
time the ledger won. This file is where that discipline meets the outside
world: if a sentence here cannot name its gate, it does not belong here.
