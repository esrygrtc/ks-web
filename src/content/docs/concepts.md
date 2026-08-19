---
title: Sessions and the two ledgers
section: Concepts
order: 10
description: The two-ledger model. A state ledger of checkpoints, an event ledger of everything between them, and why the freeze must be atomic.
---

A session is not a process and not a conversation. It is a pair of records
that together describe a piece of long-running work precisely enough to
rebuild it.

## The two ledgers

A session keeps two records that must never disagree. The **state ledger**
is the sequence of checkpoints: each one a full freeze of filesystem, model
memory, and tool state. The **event ledger** is the sequence of things that
happened between them: model calls, tool calls, steers, retries.

Every event carries the checkpoint it descended from. That parent pointer is
what makes replay deterministic and what makes a fork cheap: a fork is a new
event ledger with an old state ledger entry as its parent.

```text
state ledger   c_0000 -> c_0008 -> c_0016 -> c_0040 -> c_0041
event ledger   seq 1402, 1403, 1404, 1405, 1406, 1407 ...
fork           parent c_0040 · new event ledger from seq 0
```

The block above is an illustration of lineage, not live data. The real
guarantee behind it is gated: an agent survived kill-and-resume with the
guest and host ledgers reconciled, and the reconciliation recorded the gap
it closed. See [the proof page](/proof#gate-3).

## The five verbs

The product gives a session five verbs: run, checkpoint, fork, resume,
replay. Four are commands; the fifth is something the gateway does for you.

- `ks run` boots a new session and prints its id. The budget you set is in
  tokens; exceeding it pauses the session with a checkpoint, never a silent
  kill.
- `ks checkpoint` (alias `save`) freezes the session into content-addressed
  chunks.
- `ks fork` branches a checkpoint into divergent lineages. Each child gets
  its own lineage id, its own writable disk, and its own egress namespace.
- `ks resume` (alias `wake`) recreates the tap, restores the VMM from
  chunks, resyncs the guest clock, and reconciles the guest and host ledgers
  before the specimen wakes.
- Replay is not a verb you type. When a call is interrupted mid-flight, the
  gateway keeps the completed response and serves it from the store when the
  client asks again: billed once upstream, never billed again. `ks meter`
  shows such a row as `replayed`. Evidence: [gate 3](/proof#gate-3).

Full usage text for every verb, synced from the binary, is in the
[CLI reference](/docs/cli/).

## Why the freeze must be atomic

If the filesystem is captured at t and the model memory at t plus 40 ms, the
agent wakes into a world where it remembers writing a file that does not
exist. The three states are written as one snapshot or not at all.

A checkpoint that reports success before all three states are durable is not
a checkpoint. It is a lie with a timestamp.

That is why publishing is crash-consistent by construction: chunks, fsync,
manifest to a temp name, fsync, atomic rename. A checkpoint does not exist
until its manifest has renamed. This is not a design intention; it is gated.
A crash injected mid-publish left the previous checkpoint byte-identical
with no torn manifest visible, and a checkpoint with one flipped byte
refused to restore rather than booting garbage. See
[the proof page](/proof#gate-2b).

## Content-addressed chunks

A checkpoint is stored as fixed-size 4 MiB chunks, and a chunk's name is the
sha256 of its own uncompressed bytes. Two things fall out of that.

First, storage does not grow linearly with checkpoints: identical content is
stored once, however many freezes reference it. Measured across 82
checkpoints in a 7 hour soak: 4,233 MiB actual against 80,952 MiB naive, a
19.1x dedup ([gate 6](/proof#gate-6)).

Second, forks are cheap in storage for the same reason they are cheap in the
ledger model: a child starts from its parent's checkpoint, so the chunks
that describe the shared past are the same chunks, and only divergence costs
bytes.

Verification comes free with the naming scheme: a chunk that hashes to its
own name is intact, and a manifest whose chunks are all present is a
complete, self-contained checkpoint. The trade-offs of fixed-size chunking
and the single local store are documented honestly in
[Limits](/docs/limits/).
