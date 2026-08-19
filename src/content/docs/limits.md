---
title: Limits
section: Reference
order: 40
generated: sync-docs
---
> Synced from the product repository's own limitations file. Every limit cites a measurement or names the missing gate.

# Limitations

What KeepState cannot do at `v0.1.0-mvp`, with the evidence for each. This is
the companion to [`claims.md`](/proof): that file lists what is proven and
names the gate; this one lists what is not, and names the measurement or the
missing gate.

Every line cites its source. Where a limit is a *number*, the number is
measured rather than estimated, and the run it came from is linked. Where a
limit is an *absence*, the absence is stated as the gate that does not exist  · 
because under this project's standing invariant, an ungated sentence is not a
claim, and the honest form of "we have not proven this" is naming the proof
that is missing.

---

## 1. One provider path

**The limit.** Every gate in this repository runs against a single provider
through `ksgw`. A second host is not a second provider, and the claim was
rewritten to say so: *fresh host, fresh daemon*.

**Evidence.** [`claims.md` § Deliberately not claimed](/proof), first
bullet, which states the rewrite and what earning the original would require:
a second provider path through `ksgw`, with a gate that freezes and resumes an
agent on it. `ksgw`'s `-upstream` flag defaults to a single API endpoint
(`ksgw --help`), and no gate exercises a second value.

**What would lift it.** A provider abstraction behind the store-and-replay
path, plus a gate that repeats gate 3's assertions on the second provider. The
exactly-once billing logic is provider-shaped today: it keys on request hash
and replays a stored response body, which is a per-provider contract.

## 2. One host, and no host-loss story

**The limit.** The bench is one Mac Mini. KeepState survives *process* loss  · 
the microVM's VMM, and `ksd` itself, killed with `-9` · and has never been
asked to survive *host* loss. There is no multi-host operation, no
distribution, and no failover.

**Evidence.** [`claims.md`](/proof) refuses "production-ready" and "scales"
in exactly these words, citing that gate 6 measured one seven-hour soak rather
than a fleet. `gate-4-green` is the strongest liveness result and it kills two
processes on one machine (phase-4). The `BlobStore` interface
exists with a local-filesystem implementation; `internal/store/s3.go` is an
unimplemented stub (ADR-001 area, `decisions.md`).

**What would lift it.** A real object-store backend behind the same
`BlobStore` interface, plus a gate whose sabotage is *the host going away*
mid-session rather than a process being killed.

## 3. aarch64 only

**The limit.** The pinned stack is Apple-Silicon-shaped end to end. The
Firecracker binary, the guest kernel, and the guest rootfs base are all
aarch64, and snapshot restore requires identical pins on both sides.

**Evidence.** `versions.lock` pins
`firecracker-v1.15.1-aarch64.tgz`, `vmlinux-6.1.155` from the aarch64 CI
bucket, and `ubuntu-24.04.squashfs` likewise; `ks doctor`'s first check
verifies all pins intact. `CLAUDE.md` dragon 5 records that
aarch64 snapshot support is real and that x86-era guidance does not transfer.
No gate has ever run on x86_64.

**What would lift it.** A parallel pin set and a gate 1 run on x86_64. Nothing
in the design forbids it; nothing in the evidence supports it.

## 4. Resume is seconds, not sub-second

**The limit.** A resume completes in single-digit to low-double-digit seconds,
dominated by chunk reassembly rather than by the hypervisor.

**Evidence, measured across four phases:**

| Run | Downtime | Of which reassembly | Source |
|---|---|---|---|
| Counter guest, RAM-only | 1,504-1,645 ms | 1,552-1,586 ms | phase-6 soak cycles |
| Agent session (Claude Code) | 15,276-15,830 ms | 7,610-9,246 ms | phase-6 |
| Agent session (aider), gate 7 | 13,688 ms | · | phase-7 |
| Full demo, agent + daemon killed together | 25,200 ms | · | phase-4 |
| A ~14.5 h-old preserved checkpoint | 14,300 ms | · | phase-6 |

The VMM's own contribution is about **4 ms** (ADR-008 roadmap,
`decisions.md`): *the VMM needs 4 ms; the rest is ours.*

**Evidence of the refusal.** [`claims.md`](/proof) refuses "zero downtime"
and names what earning it requires: lazy paging or parallel reassembly, with
the breakdown re-measured.

## 5. Client retry behavior differs by agent, and is not ours to promise

**The limit.** KeepState guarantees the *gateway* side of an interrupted call:
the completed response is stored and served at zero new cost if the client
comes back for it. Whether the client comes back is the client's behavior, and
it varies by agent.

**Evidence.** Gate 7's four runs, tabulated in phase-7:

| Agent | Interrupted call absorbed on resume | Evidence |
|---|---|---|
| Claude Code | **claimed** | `gate-3-green` · retry served from store citing `original_seq=4`; 31,486 tokens excluded from spend |
| aider 0.86.2 | **not claimed** · door held **4 of 4**, walked through **3 of 4** | `gate-7-green` |

In the one run where aider did not return, the gateway had held the response
regardless: 2,556 bytes retained on disk. The gateway can hold the door open
forever; walking back through it belongs to the client.

**What would lift it.** Nothing KeepState can build alone. The honest form is
the per-agent compatibility matrix in [`claims.md`](/proof), updated only
by gate runs and never by hand.

## 6. Two agents is evidence of generality, not proof of universality

**The limit.** "Any agent works out of the box" is not claimed. Two agents
have been frozen and resumed on this bench: Claude Code (`gate-3-green`) and
aider 0.86.2 (`gate-7-green`).

**Evidence.** [`claims.md`](/proof) states the refusal and its price: more
agents behind the same gate, each with its config surface recorded as an ADR.
The encouraging half of the result is that aider's entire adaptation surface
was one line inside the guest image  · 
`export ANTHROPIC_API_BASE="${ANTHROPIC_BASE_URL:-}"` (phase-7,
ADR-010) · with `git diff --stat` over `cmd` and `internal` empty since the
gate's pinned baseline.

## 7. The durability rate is bounded by its sample, not by its successes

**The limit.** 25 of 25 fresh kill-and-resume cycles succeeded. That is 100%
observed and **86.7%** supportable at 95% confidence. The claim is the
interval, not the point.

**Evidence.** phase-6: `RESUME SUCCESS RATE: 25/25 = 100.0%,
Wilson 95% CI [86.7%, 100.0%] (denominator: fresh cycles run by this gate)`.
[`claims.md`](/proof) states that the claim moves only when the interval
does.

## 8. Storage: full snapshots, fixed chunking, local filesystem

**The limit.** No Firecracker diff snapshots; 4 MiB fixed-size chunks; one
local chunk store. Dedup does the work that diff snapshots would.

**Evidence.** ADR-001 (`decisions.md`) records the decision and
its reasoning. The measurement that justified it: 82 checkpoints occupying
**4,233 MiB actual against 80,952 MiB naive · 19.1× dedup**
(phase-6). Fixed-size chunking means an insertion that shifts
bytes defeats dedup for the remainder of a region; no workload has yet made
that cost visible, and none has been constructed to try.

## 9. Snapshot compatibility is pinned, not portable across versions

**The limit.** A checkpoint restores only on a host running the *same* pinned
Firecracker and guest kernel. There is no cross-version snapshot migration and
no format versioning beyond the pins themselves.

**Evidence.** `CLAUDE.md`, settled stack: "Snapshot and restore
MUST use identical pins," enforced by `ks doctor`'s first check against
`versions.lock`. ADR-003 records why v1.15.1 was chosen
over the newest release: v1.16.1 had no CI artifacts, so the pinned set is the
newest *self-consistent* one.

## 10. Operational edges

**Fixed in v0.1.1.** The five defects the release wrap recorded · `ks ps`
reporting dead VMMs as running, `ks demo --help` booting a demo, no garbage
collection, no human-triggered kill, and a preservation marker with an
unexpanded date format · were all fixed under the Patch Law, each with its
reproduction run RED before and GREEN after and a permanent guard in
`gates/guards.sh`. See `BACKLOG.md`.

**The limit that remains.** `ksd` exits rather than waiting when its port is
still briefly held by a predecessor, so a too-fast restart can leave the bench
with no daemon (`BACKLOG.md` #6). It is the reason gates 2a and 2b went red in
the v0.1.1 regression sweep · the race is in the daemon, and the gates were
right to expose it. Workaround and fix are both recorded there.

**Storage is collectable but not expiring.** `ks gc` reclaims session scratch
(82 G to 15 G on this bench) but nothing expires chunks: chunk-level collection
needs reference counting across manifests, and that waits on a retention policy
saying which checkpoints may die (ADR-011).

## 11. Liveness across sleep is verified, never assumed

**The limit.** The host is a Mac that sleeps. Work depending on wall-clock
must either pin the host awake or be resumable from written state.

**Evidence.** `CLAUDE.md` § Operational notes, citing the
2026-07-29 soak, whose first launch died when the Mac slept and whose second
outlived the `caffeinate` meant to protect it. The soak survived because it
was resumable from its ledger; the protection did not survive at all. This is
recorded as a property of the bench, not a defect of the product · but a fleet
would have to solve it rather than document it.

---

## How to read this file

This is diligence armor, not confession. Every limit here is either a number
that was measured or a gate that does not exist, and both are written the way
they are because the alternative · a softened claim in `claims.md` · is the
one failure mode this project spent nine gates preventing.

Three times during the build a measurement contradicted a belief: a soak found
a connection leak that twenty-five clean cycles could not see; the project's
own cleanup destroyed an artifact a preservation ruling had protected; and a
gate passed an assertion on empty evidence while the system under test was
healthy. Each time the ledger won. This file is where that discipline faces
outward.
