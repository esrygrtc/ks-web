# OPERATOR.md — running the bench

Everything here was executed on this bench during the release wrap of
2026-07-31 and its real output pasted in. Where a command was deliberately
*not* executed, it says so and says why. Timings are measured on the build
machine (Mac Mini, Apple Silicon, 8 vCPU / 16 GiB allocated to `ks-host`).

**The one rule that prevents most incidents:** never confuse the worlds.
WORLD 1 is macOS, where you type. WORLD 2 is `ks-host`, the Lima VM where
every microVM, tap device, chunk, and secret lives — reached by prefixing
`limactl shell ks-host --`. WORLD 3 is the guest microVMs inside it. Almost
every command below is a WORLD 1 command that runs something in WORLD 2, and
almost all of them need `sudo` in WORLD 2, because the chunk store, the guest
SSH key, and the provider key are all root-owned.

---

## 1. Cold start to a healthy bench

Measured end to end at **19 seconds** from a stopped VM to a clean doctor.

```bash
limactl start ks-host --tty=false
limactl shell ks-host -- sudo bash -c '
tmux new-session -d -s ks-ksd "ksd  >>/var/lib/keepstate/ksd.log  2>&1"
tmux new-session -d -s ks-gw  "ksgw >>/var/lib/keepstate/ksgw.log 2>&1"
sleep 3
ks doctor'
```

Expected tail — anything less than a full pass means stop and read section 6.
The count is derived from the checks that ran, so it grows when doctor learns a
new hazard; at v0.1.1 it is 9:

```
PASS: versions.lock present, parses, all pins intact (/Users/c/keepstate/versions.lock)
PASS: data dir /var/lib/keepstate writable
PASS: /dev/kvm is a character device
PASS: free disk 95G >= 50G
PASS: no stray firecracker processes
PASS: no stray ks-* tap interfaces
PASS: no leaked fork egress (ksns-*/ksv-*)
PASS: preserved artifact markers well-formed (1 artifact(s))
PASS: preserved/ intact or grown since last census (1 artifact(s), 589 files, 738.1 MiB)
RESULT: doctor OK (9/9 checks passed)
```

`limactl start` alone took 13 s; the daemons and doctor took the rest. The
two daemons are deliberately started separately and never as services: they
live in named tmux sessions inside WORLD 2 so that a human can attach to
either one and watch it work. Nothing is orphaned, ever.

Confirm both are up:

```bash
limactl shell ks-host -- sudo tmux ls
```
```
ks-gw: 1 windows (created Fri Jul 31 12:55:09 2026)
ks-ksd: 1 windows (created Fri Jul 31 12:55:09 2026)
```

## 2. Clean stop

Measured at **3 seconds**. Stop the daemons first so nothing writes while the
VM goes down, then stop the VM.

```bash
limactl shell ks-host -- sudo bash -c '
tmux kill-session -t ks-gw  2>/dev/null || true
tmux kill-session -t ks-ksd 2>/dev/null || true
sleep 1
echo "firecracker procs: $(pgrep -c firecracker 2>/dev/null || echo 0)"'
limactl stop ks-host
limactl list
```

Any live sessions die with the VM. If you want them back afterwards,
checkpoint them **before** stopping — that is the entire product:

```bash
limactl shell ks-host -- sudo ks checkpoint <session-id>
```

Stopping the host does **not** corrupt anything: checkpoints are published
crash-consistently (`gate-2b-green`), so the worst case is losing the work
since the last checkpoint. Every VMM dies without a state write, but since
v0.1.1 `ks ps` verifies liveness rather than reporting the last transition, so
those sessions read `dead` on the next look and say so in their event logs.

## 3. Where everything lives

All paths are inside WORLD 2. Nothing operational lives on the macOS side
except the repository itself.

| Path | What it is |
|---|---|
| `/var/lib/keepstate/chunks` | the content-addressed chunk store — **8.2 G**, 10,238 chunk files across 256 shard directories at wrap time |
| `/var/lib/keepstate/sessions/<id>/` | per-session disk overlay, snapshot scratch, serial logs, `events.jsonl` |
| `/var/lib/keepstate/images/` | guest images (`counter`, `claude`, `aider`) plus their `.json` descriptors |
| `/var/lib/keepstate/artifacts/` | pinned downloads: firecracker, kernel, rootfs base |
| `/var/lib/keepstate/preserved/` | artifacts under a preservation ruling — **immutable**, see section 7 |
| `/var/lib/keepstate/keys/id_ed25519` | guest SSH key, mode 600 root |
| `/var/lib/keepstate/ks.db` | SQLite session metadata |
| `/var/lib/keepstate/ksd.log`, `ksgw.log` | daemon logs (append-only; the tmux panes show the same thing live) |
| `/etc/keepstate/ksgw.env` | **the provider key**, mode 600 root, outside the repo |
| `/usr/local/bin/{ksd,ksgw,keepstate,ks,firecracker}` | binaries; `ks` is a symlink to `keepstate` |
| `/Users/<you>/keepstate` | the repository, mounted into WORLD 2 at the same path |

Storage: 8.2 G of chunks, 741 M preserved, and session directories that grew
to 82 G before `ks gc` reclaimed them to 15 G. The chunk store is the efficient
part — 19.1× dedup across 82 checkpoints (`gate-6-green`); the per-session
scratch is the expensive part, and section 6 is where you collect it.

## 4. Day-to-day commands

Every one of these was run during the wrap.

```bash
# what exists, and what is supposedly alive
limactl shell ks-host -- sudo ks ps
limactl shell ks-host -- sudo ks ps --json

# the executable form of every hazard this project has hit
limactl shell ks-host -- sudo ks doctor

# a session's model traffic, one JSON line per call
limactl shell ks-host -- sudo ks logs <session-id>

# what a session cost, per call, replays excluded from spend
limactl shell ks-host -- sudo ks meter <session-id>
```

`ks meter` is where exactly-once billing becomes visible. From the wrap's own
demo run — note seq 6, served from the store after the kill:

```
SEQ    STATUS    IN       OUT      CACHE_C  CACHE_R  LAT_MS    RETRY
5      200       2        354      257      33528    5633
6      200       2        118      29752    0        13        replayed
7      200       2        137      30853    0        3019
total calls: 10, budget spend (excl. replays): 293325 tokens
```

The corresponding `ks logs` line carries `"new_cost":0` and
`"original_seq":1` — the interrupted call, absorbed for free.

The full verb set is `run, ps, attach, checkpoint (save), resume (wake), fork,
gc, inspect-file, kill, logs, meter, demo, soak, ledger, doctor`. Ask any of
them what they do — `ks <verb> --help` prints usage and does nothing else, and
bare `ks` prints the index.

**Watching a daemon live** — attach to its tmux session, and detach with
`Ctrl-b d`:

```bash
limactl shell ks-host -- sudo tmux attach -t ks-gw
```

This is the one command in this file not executed during the wrap, because it
is interactive and this session is not a terminal. `sudo tmux ls` was run
instead, and is the safe way to check.

**Gateway health**, without attaching to anything:

```bash
limactl shell ks-host -- curl -s http://127.0.0.1:7445/status
```
```json
{"active":{"49267d83903f":0},"disable_seq":false,"disable_store":false,"seqs":{"49267d83903f":5}}
```

`active` is in-flight calls per session, `seqs` is each lineage's sequence
head. The two `disable_*` flags must both read `false` on a real bench — they
exist so gates can sabotage the gateway, and a `true` here means someone left
a sabotage run's environment behind.

**Reading a soak ledger** — always through `ks ledger`, never with an ad-hoc
parser. That rule exists because a hand-written parser once produced six false
alarms and one false comfort against a healthy system:

```bash
limactl shell ks-host -- sudo ks ledger selfcheck   # 'ledger_selfcheck 1' means the read path is sane
limactl shell ks-host -- sudo ks ledger stat
```
```
slots_scheduled 82
checkpoints_ok 82
checkpoints_failed 0
doctor_samples 13
elapsed_seconds 24932
```

## 5. Running the demo

```bash
limactl shell ks-host -- sudo ks demo --task fixture --kill-at 3m --headless
```

Needs the provider key in place. Takes about **11 minutes** end to end and
writes a report to `/var/lib/keepstate/demo-report.md`. For the on-camera
version, with the beats and the expected output at each one, see
[`DEMO_SCRIPT.md`](DEMO_SCRIPT.md).

Do **not** type `ks demo --help`: it does not print usage, it starts a demo
(`BACKLOG.md` entry 2).

Long runs — demos, gates, soaks — belong in a named tmux session so that a
disconnect cannot kill them:

```bash
limactl shell ks-host -- sudo tmux new-session -d -s ks-demo \
  "ks demo --task fixture --kill-at 3m --headless >/var/lib/keepstate/demo-rehearsal.log 2>&1"
limactl shell ks-host -- sudo tail -f /var/lib/keepstate/demo-rehearsal.log
```

## 6. When something is wrong

**`ks doctor` is the first move, always.** It is the executable form of every
hazard this project has hit, and every gate calls it first.

| Symptom | What it means | What to do |
|---|---|---|
| `doctor` reports stray firecracker processes | a previous run died without cleanup | `sudo pkill -f firecracker`, then re-run doctor |
| `doctor` reports stray `ks-*` taps or `ksns-*`/`ksv-*` | a fork's egress plumbing leaked | `sudo ks doctor` names them; delete with `ip link del <name>` |
| `doctor` reports free disk under 50 G | session directories, not chunks | see below |
| `ks ps` shows `running` for a dead session | should not happen since v0.1.1: `ps` verifies liveness at read time | if seen, that is a regression of BACKLOG #1; check the session's `state.reconciled` events and file it |
| a guest is unreachable over SSH | key is root-only | you forgot `sudo` |
| gateway returns auth errors | key rotated under a running `ksgw` | restart `ksgw` — section 8 |

**Disk.** Session directories, not chunks, are what fill a bench: 38 of them
held 82 G at v0.1.0 while the entire chunk store held 8.2 G. Since v0.1.1 this
is `ks gc`'s job, and it reclaimed that tree to 15 G:

```bash
limactl shell ks-host -- sudo ks gc          # dry run: lists what it would reclaim
limactl shell ks-host -- sudo ks gc --yes    # actually reclaim
```

```
would reclaim 75541.6 MiB across 61 path(s) in 33 session(s)
dry run: nothing was deleted. Re-run with --yes to reclaim.
```

gc deletes only what a resume can rebuild (ADR-011): the `disk.ext4` overlay,
`restore/` and `ckpt/` of sessions that have no live VMM **and** a published
manifest. Sessions without a manifest are skipped with that reason — their
disk is not scratch, it is the only copy. Chunks, manifests, ledgers, serial
logs and everything under `preserved/` are ineligible by construction, and
doctor check 9 independently watches that `preserved/` never shrinks.

Every deleting run is recorded in `/var/lib/keepstate/gc.jsonl` and in each
session's own event log, naming the paths, the bytes, and the manifest that
made them rebuildable. Read the ledger before wondering where something went:

```bash
limactl shell ks-host -- sudo tail -3 /var/lib/keepstate/gc.jsonl
```

**The blocked protocol.** Three failed attempts with three genuinely different
hypotheses on one problem means stop: write down the symptom, the hypotheses,
the evidence for and against each, and the exact reproduction commands. This
project's constitution requires it of the builder, and it is the right
discipline for an operator too.

## 7. Preserved artifacts

`/var/lib/keepstate/preserved/` holds artifacts under a written preservation
ruling. They are **immutable until the ruling is lifted in writing**, and
cleanup routines never override preservation.

```bash
limactl shell ks-host -- sudo bash -c 'for d in /var/lib/keepstate/preserved/*/; do
  echo "$(basename $d): chunks=$(find $d/chunks -type f | wc -l) $(du -sh $d | cut -f1) marker=$([ -f $d/PRESERVED ] && echo yes || echo NO)"
done'
```
```
soak-20712ae21ba9: chunks=587 741M marker=yes
```

Count with `find -type f`, not `ls`. The store is sharded two hex digits deep,
so `ls chunks | wc -l` counts *shard directories* — 225 of them here — and
looks like a plausible chunk count while being nothing of the sort. The wrap
made exactly that mistake before catching it.

To verify an artifact is genuinely self-contained, check that every chunk its
manifest references is present:

```bash
limactl shell ks-host -- sudo python3 -c "
import json,os
D='/var/lib/keepstate/preserved/soak-20712ae21ba9'
present={f for _,_,fs in os.walk(D+'/chunks') for f in fs}
refs={c for f in json.load(open(D+'/manifest.json'))['files'].values() for c in f['chunks']}
assert refs, 'no chunk references parsed - refusing to report on empty evidence'
print('refs=%d present=%d missing=%d' % (len(refs), len(refs&present), len(refs-present)))"
```
```
refs=587 present=587 missing=0
```

The `assert refs` is not decoration. The first version of this command guessed
the manifest's shape wrong and printed `refs=0 present=0 missing=0` — a clean
bill of health computed from nothing. That is the same defect that made a gate
pass on empty evidence during Phase 6, and the rule that came out of it applies
to operators too: **evidence validity before evidence value.** A check that can
report success on absent data is worse than no check.

Chunks are content-addressed: a file's name is the sha256 of its *uncompressed*
bytes, so integrity is checkable without any index at all —
`zstd -dc <chunk> | sha256sum` must reproduce the filename. Three chunks
spot-checked this way during the wrap, all matching.

That artifact is a ~14.5-hour-old checkpoint that was woken in 14.3 s during
gate 6 — reproducible evidence that a checkpoint does not go stale. Each
preserved artifact is self-contained (its own manifest *and* its own chunks)
because an earlier one was not: the project's own `rm -rf .../chunks`
destroyed the chunks behind a manifest that a ruling had already protected.
The `PRESERVED` marker file names the ruling that protects it.

## 8. The provider key

The key lives at `/etc/keepstate/ksgw.env`, mode **600**, owner **root**,
outside the repository. Verified during the wrap:

```bash
limactl shell ks-host -- sudo stat -c '%n mode=%a owner=%U:%G' /etc/keepstate/ksgw.env
```
```
/etc/keepstate/ksgw.env mode=600 owner=root:root
```

Guests never hold it. Each session gets a virtual key (`ks_sk_<session>`) and
an `ANTHROPIC_BASE_URL` pointing at `ksgw`, which is what makes per-session
budgets and exactly-once billing enforceable at all.

**Rotation runbook — order matters.** A rotated file under a running daemon is
a rotation that has not happened yet:

1. Write the new key into the root-only file via a **no-echo read**, in
   canonical `KS_ANTHROPIC_KEY=<value>` form. Secrets never appear in command
   arguments or shell history, and never in a conversation with a builder — a
   key that is pasted into a conversation is a rotated key.
2. Restart the gateway: `sudo tmux kill-session -t ks-gw`, then start it again
   exactly as in section 1 — but **wait for the port between stop and start**.
   A daemon restarted too quickly can bind before its predecessor has released
   the socket, log `address already in use`, and exit, leaving the bench with
   no daemon at all (`BACKLOG.md` #6):

   ```bash
   limactl shell ks-host -- sudo bash -c '
   tmux kill-session -t ks-gw 2>/dev/null; pkill -x ksgw 2>/dev/null
   for i in $(seq 1 20); do ss -ltn | grep -q 127.0.0.1:7443 || break; sleep 0.5; done
   tmux new-session -d -s ks-gw "ksgw >>/var/lib/keepstate/ksgw.log 2>&1"'
   ```
3. Verify: `curl -s http://127.0.0.1:7445/status`, then one real call.

Step 1 is the only command in this file that was **not** executed during the
wrap, and deliberately: executing it would mean handling the key. Steps 2 and
3 use commands from section 1 and section 4, both of which were.

The wrap also ran a read-only secret sweep over the repository and its entire
git history — every blob on every ref — and found no key material and no
private keys tracked. See the release wrap entry in `JOURNAL.md`.

## 9. Rebuilding from nothing

If the bench is gone entirely, [`QUICKSTART.md`](QUICKSTART.md) builds one from
a clean clone in about 20 minutes, on a machine that has never seen KeepState.
Those commands are not aspirational: `gate-7-green` extracts them mechanically
from that file and runs them on a fresh VM, so if they stop working the gate
goes red.
