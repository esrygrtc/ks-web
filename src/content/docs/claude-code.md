---
title: Claude Code on KeepState
section: Guides
order: 20
description: Migrate a running Claude Code task onto durable infrastructure without changing how you work.
---

Claude Code runs unmodified on KeepState. You do not change your prompts,
your tools, or your workflow; you change where the process lives. What
follows is a real migration of a long-running task.

Every command below is the CLI as it ships today. Where this guide states a
measured number, the number links to the gate run that produced it.

## Start it on KeepState

Point at your workspace. The image ships with Claude Code and the tools it
expects. The budget is a per-session token budget enforced by the gateway
(default 2,000,000); exceeding it pauses the session with a checkpoint,
never a silent kill.

```bash
SID=$(ks run --image claude --workspace ./payments-migration --budget 2000000)
echo "session: $SID"
```

`ks run` prints the new session id; everything else in this guide takes that
id. If you want to watch the agent work, `ks attach $SID` drops you into its
tmux (detach with Ctrl-b d). Humans attach, never own.

## Checkpoint it

A checkpoint is a full freeze of filesystem, model memory, and tool state,
published crash-consistently: it does not exist until its manifest has
renamed.

```bash
ks checkpoint $SID
```

There is no cadence flag on `ks run` today. On-demand `ks checkpoint` is the
production surface; the automatic cadence you may see in demo output belongs
to `ks demo` and `ks soak`, the rehearsal harnesses.

## Pull the plug

Wait until the agent is genuinely mid-task, then kill it the ugly way. No
graceful shutdown, no signal handler. `ks ps --json` reports the VMM pid,
verified live at read time rather than remembered.

```bash
kill -9 $(ks ps --json | python3 -c "import json,sys;print([s for s in json.load(sys.stdin) if s['id']=='$SID'][0]['fc_pid'])")
ks ps   # the session now reads: dead
```

## Resume it

```bash
ks resume $SID
```

The resume recreates the tap, restores the VMM from chunks, resyncs the
guest clock, and reconciles the guest and host ledgers before the specimen
wakes. The agent comes back inside the same thought, with the same files and
the same memory of what it was doing. Measured agent-session downtime across
gate runs: [13.7-25.2 s](/proof), of which the hypervisor's own part is
about 4 ms; chunk reassembly dominates ([Limits](/docs/limits/)).

> **What you just proved.** You killed a process that had been working for
> minutes and lost nothing: not the filesystem, not the model's memory of
> the conversation, not the half-finished thought. That is the whole
> product. Everything else is scale, budgets, and evidence.

## Fork before a risky decision

Branch the freeze rather than gambling the run. Each fork is a conversation
that went differently. Steering rides on the fork: `--steer` takes a file
with one steering line per branch, injected by the gateway into that
branch's next model call and never written into the guest.

```bash
ks fork $SID -n 3 --steer steers.txt
```

```text
one big migration
keep legacy adapter
split by tenant
```

Each child gets its own lineage id, its own writable disk, and its own
egress namespace. The steer is recorded with pre-steer and post-steer body
hashes, which is how [gate 5](/proof#gate-5) proved three siblings differed
by their steering and by nothing else: base sha256 identical on all three,
steered bodies all distinct.

## The receipt

```bash
ks meter $SID
```

`ks meter` shows what the session cost, per call. The RETRY column shows
`replayed` for a call served from the store after an interruption: billed
once upstream, never billed again. For Claude Code this absorption is a
gated claim, not a hope: the retry after the kill above is served from the
store instead of bought twice ([gate 3](/proof#gate-3)).

## Known limitation

Claude Code's own `--resume` and a KeepState resume are different objects.
Its resume replays your notes into a fresh world; ours thaws the world.
Running both is harmless but redundant.
