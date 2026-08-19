---
title: FAQ
section: Operations
order: 51
description: Short answers with evidence links. Durability, resume time, billing on interruption, agent compatibility, and what is honestly not promised yet.
---

Every answer here is either a measurement with its gate linked, an offer
from the [pricing page](/pricing), or an honest absence. Nothing below is
aspiration.

## Is my data safe if the host dies?

Not yet, and we will not pretend otherwise. KeepState survives process loss:
the microVM's VMM and the supervising daemon, killed together with `kill -9`,
came back with the work intact ([gate 4](/proof#gate-4)). It has never been
asked to survive host loss: the bench is a single host, checkpoints live in
a local chunk store, and there is no multi-host operation and no failover.
The object-store backend that would change this is an unimplemented stub.
The full statement, with what would lift each limit, is in
[Limits](/docs/limits/).

## How long does a resume take?

Seconds, not sub-second: [13.7-25.2 s](/proof) measured across gate runs
(13.7 s for an aider session, 25.2 s for the full demo where the daemon was
killed along with the agent). The hypervisor's own snapshot load is about
4 ms; chunk reassembly dominates the rest. "Zero downtime" is explicitly
refused on the [proof page](/proof#not-claimed).

## Does my agent need changes to run on KeepState?

Claude Code ran unmodified ([gate 3](/proof#gate-3)). For aider, the entire
adaptation surface was one exported line inside the guest image,
`export ANTHROPIC_API_BASE="${ANTHROPIC_BASE_URL:-}"`, with zero core
changes: the diff over the product's `cmd` and `internal` trees is empty
since the gate's pinned baseline ([gate 7](/proof#gate-7)).

## What gets billed on an interrupted model call?

At most once, and the gateway enforces it rather than trusting the client.
A completed response caught by a kill is retained and served from the store
on retry; that row appears in `ks meter` as `replayed`, with zero new
tokens ([gate 3](/proof#gate-3)). Whether your client walks back through
the held door is per-agent behavior; see the
[compatibility matrix](/compatibility).

## Which agents work today?

Two, each behind a gate run: Claude Code (interrupted call absorbed on
resume, claimed) and aider 0.86.2 (door held 4 of 4, walked through 3 of 4,
so the absorption is observed, not claimed). The
[compatibility matrix](/compatibility) grows only when a gate runs; rows
are never written by hand.

## What happens when a session hits its budget?

Budgets are tokens, set per session at `ks run --budget` (default
2,000,000). Exceeding the budget pauses the session with a checkpoint,
never a silent kill. The pause is a freeze, so nothing is lost, and
`ks meter` shows where every token went.

## Do old checkpoints go stale?

No. A checkpoint about 14.5 hours old was woken in
[14.3 s](/proof#gate-6), reading its frozen counter at 63 while its living
twin had reached 4841. A checkpoint is a complete, self-contained object:
a manifest plus content-addressed chunks.

## What do I pay for?

Three meters, one bill: session-minutes while a VM is awake, checkpoint
storage after dedup, and managed tokens only if you use our inference.
Bring your own provider keys and the third meter disappears; we meter
durability only. Plans and rates are on the [pricing page](/pricing).

## Can I self-host KeepState?

No. By founder decision the core stays unlicensed, all rights reserved, and
runs as a hosted product. The han protocol is extracted to its own
repository under Apache-2.0 the day the first design partner is live: an
event, not a date, because a protocol with no implementers is documentation
with a patent grant attached.

## Where do these answers come from?

From the same place the [proof page](/proof) does: the product repository's
claims file, synced rather than retyped. If an answer here cannot name its
gate, its offer, or its honest absence, it does not belong here.
