# KeepState quickstart

From a fresh clone to your first kill-and-resume. Every command below is
literal. Gate 7 extracts these blocks mechanically and runs them on a machine
that has never built KeepState — if they stop working, the gate goes red.

**What you need:** a Mac on Apple Silicon (M3 or newer, macOS 15+) with
Homebrew, and about 20 minutes. No API key is required for the quickstart:
the first kill-and-resume uses a RAM-only counter guest, not an agent.

**What you get:** a microVM whose memory you freeze, kill `-9`, and wake — and
a printed proof that it is the *same* memory, not a fresh boot.

---

## 1. The bench

KeepState runs Firecracker microVMs, which need KVM, which needs a Linux host.
On a Mac that means one nested virtualization layer: a Lima VM (WORLD 2) that
hosts the microVMs (WORLD 3). Everything below runs from your Mac (WORLD 1).

```bash
brew list lima >/dev/null 2>&1 || brew install lima
git clone https://github.com/esrygrtc/ks.git ~/keepstate-quickstart || true
cd ~/keepstate-quickstart
limactl start --name=ks-host2 infra/ks-host2.yaml --tty=false
limactl shell ks-host2 -- test -c /dev/kvm && echo "KVM present — the bench can host microVMs"
```

## 2. Toolchain and pinned artifacts

Versions are pinned in `versions.lock` and verified by sha256. Snapshot and
restore must use identical pins, so nothing here floats.

```bash
limactl shell ks-host2 -- sudo bash -c '
set -e
DEBIAN_FRONTEND=noninteractive apt-get update -q >/dev/null
DEBIAN_FRONTEND=noninteractive apt-get install -yq build-essential curl e2fsprogs squashfs-tools tmux >/dev/null
cd /tmp
curl -fsSLO https://go.dev/dl/go1.26.5.linux-arm64.tar.gz
echo "fe4789e92b1f33358680864bbe8704289e7bb5fc207d80623c308935bd696d49  go1.26.5.linux-arm64.tar.gz" | sha256sum -c -
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.26.5.linux-arm64.tar.gz
ln -sf /usr/local/go/bin/go /usr/local/bin/go
mkdir -p /var/lib/keepstate/artifacts && cd /var/lib/keepstate/artifacts
curl -fsSLO https://github.com/firecracker-microvm/firecracker/releases/download/v1.15.1/firecracker-v1.15.1-aarch64.tgz
curl -fsSLO https://github.com/firecracker-microvm/firecracker/releases/download/v1.15.1/firecracker-v1.15.1-aarch64.tgz.sha256.txt
sha256sum -c firecracker-v1.15.1-aarch64.tgz.sha256.txt
tar -xzf firecracker-v1.15.1-aarch64.tgz
install -m755 release-v1.15.1-aarch64/firecracker-v1.15.1-aarch64 /usr/local/bin/firecracker
curl -fsS -o vmlinux-6.1.155 https://s3.amazonaws.com/spec.ccfc.min/firecracker-ci/v1.15/aarch64/vmlinux-6.1.155
curl -fsS -o ubuntu-24.04.squashfs https://s3.amazonaws.com/spec.ccfc.min/firecracker-ci/v1.15/aarch64/ubuntu-24.04.squashfs
firecracker --version | head -1'
```

## 3. Build KeepState and its counter guest

```bash
limactl shell ks-host2 -- bash -c '
export PATH=/usr/local/go/bin:$PATH
rm -rf ~/ks-build && mkdir -p ~/ks-build
cp -r /Users/'"$USER"'/keepstate-quickstart/go.mod /Users/'"$USER"'/keepstate-quickstart/go.sum \
      /Users/'"$USER"'/keepstate-quickstart/cmd /Users/'"$USER"'/keepstate-quickstart/internal ~/ks-build/
cd ~/ks-build && go build -o ksd ./cmd/ksd && go build -o keepstate ./cmd/keepstate
sudo install -m755 ksd /usr/local/bin/ksd
sudo install -m755 keepstate /usr/local/bin/keepstate
sudo ln -sf /usr/local/bin/keepstate /usr/local/bin/ks'
limactl shell ks-host2 -- sudo /Users/$USER/keepstate-quickstart/infra/hello-vm.sh prepare
limactl shell ks-host2 -- sudo bash -c '
mkdir -p /var/lib/keepstate/images
cp /var/lib/keepstate/artifacts/hello.ext4 /var/lib/keepstate/images/counter.ext4
printf "%s\n" "{\"ssh\": false, \"readonly\": true, \"mem_mib\": 512, \"init\": \"/sbin/ks-hello-init\"}" \
  > /var/lib/keepstate/images/counter.json
ks doctor | tail -1'
```

## 4. Your first kill-and-resume

Boot a guest whose only interesting state lives in RAM: it picks a random
nonce at boot and counts upward, writing nothing to disk. Checkpoint it, kill
the VMM with `-9`, then wake it. Same nonce and a continuing count means the
memory survived; a new nonce would mean you merely rebooted.

```bash
limactl shell ks-host2 -- sudo bash -c '
set -e
export KS_VERSIONS_LOCK=/Users/'"$USER"'/keepstate-quickstart/versions.lock
tmux kill-session -t ks-ksd 2>/dev/null || true
tmux new-session -d -s ks-ksd "ksd >>/var/lib/keepstate/ksd.log 2>&1"
sleep 2
SID=$(ks run --image counter 2>/dev/null)
echo "session: $SID"
sleep 6
PRE=$(grep "^KS NONCE=" /var/lib/keepstate/sessions/$SID/proc-0/serial.log | tail -1 | tr -d "\r")
echo "before the kill: $PRE"
ks checkpoint $SID
PID=$(ks ps --json | python3 -c "import json,sys;print([s for s in json.load(sys.stdin) if s[\"id\"]==\"$SID\"][0][\"fc_pid\"])")
kill -9 $PID
sleep 2
ks resume $SID
for i in $(seq 1 20); do
  POST=$(grep "^KS NONCE=" /var/lib/keepstate/sessions/$SID/proc-1/serial.log 2>/dev/null | tail -1 | tr -d "\r")
  [ -n "$POST" ] && break
  sleep 1
done
echo "after the resume: $POST"
PN=$(echo "$PRE"  | sed "s/.*NONCE=\([0-9a-f]*\).*/\1/"); PC=$(echo "$PRE"  | sed "s/.*COUNT=\([0-9]*\).*/\1/")
QN=$(echo "$POST" | sed "s/.*NONCE=\([0-9a-f]*\).*/\1/"); QC=$(echo "$POST" | sed "s/.*COUNT=\([0-9]*\).*/\1/")
if [ "$PN" = "$QN" ] && [ -n "$QC" ] && [ "$QC" -gt "$PC" ]; then
  echo "QUICKSTART-RESUME-OK same nonce $PN, count $PC -> $QC"
else
  echo "QUICKSTART-RESUME-FAILED pre=$PRE post=$POST"; exit 1
fi
ks kill $SID >/dev/null'
```

If you see `QUICKSTART-RESUME-OK`, you have killed a running machine and
brought it back with its memory intact.

## 5. Where to go next

- `ks doctor` — the executable form of every hazard this project has hit.
- `ks demo --task fixture --kill-at 3m --headless` — the full demo: a real
  agent killed along with its own daemon, back at work in ~25 s. Needs a
  provider key in `/etc/keepstate/ksgw.env` (mode 600, root-owned).
- `docs/claims.md` — every public claim and the gate tag that proves it.

## Cleanup

```bash
limactl stop ks-host2 || true
limactl delete ks-host2 --force || true
```
