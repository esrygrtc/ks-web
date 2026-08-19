package main

import (
	"fmt"
	"io"
	"sort"
	"strings"
)

// Usage lives here, ahead of every side effect. BACKLOG defect #2 was that
// `ks demo --help` booted a microVM instead of answering the question: the
// demo consumed its argv without ever looking for a help flag. The reflex
// before typing an unfamiliar command is to ask it what it does, and a tool
// that answers that question by doing the thing has broken a promise nobody
// thought to write down.

type verbHelp struct {
	synopsis string // one line, shown in the top-level list
	usage    string // full usage, shown for `ks <verb> --help`
}

var verbs = map[string]verbHelp{
	"run": {
		"boot a new session and print its id",
		`usage: ks run [--image NAME] [--workspace PATH] [--budget TOKENS]

  --image NAME       guest image to boot (default "base"; e.g. counter, claude, aider)
  --workspace PATH   host path vendored into the guest workspace
  --budget TOKENS    per-session token budget enforced by ksgw (default 2000000)

Prints the new session id. Exceeding the budget pauses the session with a
checkpoint, never a silent kill.`,
	},
	"ps": {
		"list sessions and their true state",
		`usage: ks ps [--json]

  --json   machine-readable output

STATE is verified against the recorded VMM process at read time, not merely
reported from the last transition (BACKLOG #1). A session whose VMM is gone
reads "dead", whatever the database last wrote.`,
	},
	"attach": {
		"attach to a session's tmux (humans attach, never own)",
		`usage: ks attach SESSION

Attaches to tmux session "main" inside the guest. Detach with Ctrl-b d.`,
	},
	"checkpoint": {
		"freeze a session into content-addressed chunks (alias: save)",
		`usage: ks checkpoint SESSION [--stop]

  --stop   leave the microVM stopped after the checkpoint

Publishing is crash-consistent: chunks, fsync, manifest to a temp name, fsync,
atomic rename. A checkpoint does not exist until its manifest has renamed.`,
	},
	"resume": {
		"wake a checkpointed session (alias: wake)",
		`usage: ks resume SESSION

Recreates the tap, restores the VMM from chunks, resyncs the guest clock, and
reconciles the guest and host ledgers before the specimen wakes.`,
	},
	"fork": {
		"branch a checkpoint into divergent lineages",
		`usage: ks fork SESSION [-n COUNT] [--steer FILE]

  -n COUNT       number of children (default 1)
  --steer FILE   per-branch steering text, injected by ksgw, never in the guest

Each child gets its own lineage id, its own writable disk, and its own egress
namespace, so identical guest IPs coexist.`,
	},
	"inspect-file": {
		"read a file out of a session's guest",
		`usage: ks inspect-file SESSION PATH`,
	},
	"kill": {
		"terminate a session and free its tap",
		`usage: ks kill SESSION`,
	},
	"logs": {
		"a session's gateway call log, one JSON line per call",
		`usage: ks logs SESSION [-n LINES]

  -n LINES   how many lines to show (default 20)`,
	},
	"meter": {
		"what a session cost, per call, replays excluded from spend",
		`usage: ks meter SESSION [--json]

The RETRY column shows "replayed" for a call served from the store after an
interruption: billed once upstream, never billed again.`,
	},
	"demo": {
		"the full demo: an agent killed with its own daemon, then resumed",
		`usage: ks demo [--task NAME] [--kill-at DURATION|manual] [--wait-for-kill]
            [--checkpoint-every DURATION] [--budget TOKENS] [--headless]
            [--report PATH] [--no-checkpoint]

  --task NAME              fixture task to vendor (default "fixture")
  --kill-at DURATION       kill this long after the specimen starts (default 3m).
                           Use "manual" to wait for a human instead.
  --wait-for-kill          arm, print the kill instruction, and block until a
                           human kills the VMM by hand. Same as --kill-at manual.
  --checkpoint-every DUR   checkpoint cadence (default 5m)
  --budget TOKENS          session token budget (default 400000)
  --headless               no tmux attach; log to stdout
  --report PATH            where to write the run report
  --no-checkpoint          SABOTAGE: disable checkpointing, so resume must fail

Needs a provider key in /etc/keepstate/ksgw.env (mode 600, root-owned) and
must run as root, because the guest key and the chunk store are root-only.`,
	},
	"gc": {
		"reclaim rebuildable scratch from sessions with no live VMM",
		`usage: ks gc [--yes] [--json]

  (default)  dry run: list what would be reclaimed and how many bytes
  --yes      actually delete
  --json     machine-readable output

gc deletes only what a resume can rebuild: per-session scratch and reassembled
per-generation state, and only for sessions with no live VMM. Chunks,
manifests, ledgers, and everything under preserved/ are ineligible by
construction (ADR-011). Every run that deletes writes a ledger event naming
what it removed and why it was rebuildable.`,
	},
	"soak": {
		"long-run checkpoint cadence with health sampling",
		`usage: ks soak [--duration D] [--checkpoint-every D] [--doctor-every D] [--budget TOKENS]`,
	},
	"ledger": {
		"read a soak ledger through production code",
		`usage: ks ledger stat|witness|cycles|selfcheck [PATH]

Gates read ledgers only through this command. A hand-written parser once
produced six false alarms and one false comfort against a healthy system.`,
	},
	"doctor": {
		"the executable form of every hazard this project has hit",
		`usage: ks doctor

Exits 0 only if every check passes. The check count is derived from the checks
that ran, never hardcoded.`,
	},
}

var aliases = map[string]string{"save": "checkpoint", "wake": "resume"}

// printUsage writes usage for one verb, or the full list when verb is empty or
// unknown. Never touches the bench.
func printUsage(out io.Writer, verb string) {
	if canon, ok := aliases[verb]; ok {
		verb = canon
	}
	if h, ok := verbs[verb]; ok {
		fmt.Fprintln(out, h.usage)
		return
	}
	names := make([]string, 0, len(verbs))
	for n := range verbs {
		names = append(names, n)
	}
	sort.Strings(names)
	fmt.Fprintln(out, "usage: ks <verb> [flags]    (ks <verb> --help for one verb)")
	fmt.Fprintln(out)
	for _, n := range names {
		fmt.Fprintf(out, "  %-13s %s\n", n, verbs[n].synopsis)
	}
	fmt.Fprintln(out)
	fmt.Fprintln(out, "aliases: save=checkpoint, wake=resume")
	if verb != "" {
		fmt.Fprintf(out, "\nunknown verb %q\n", verb)
	}
}

// wantsHelp reports whether argv asks for usage. Checked before any subcommand
// runs, so that no side effect can precede the answer.
func wantsHelp(args []string) bool {
	for _, a := range args {
		if a == "--help" || a == "-h" || a == "help" {
			return true
		}
	}
	return false
}

// helpTopic returns the verb whose usage was requested.
func helpTopic(args []string) string {
	for _, a := range args {
		if a == "--help" || a == "-h" || a == "help" {
			continue
		}
		if strings.HasPrefix(a, "-") {
			continue
		}
		if _, ok := verbs[a]; ok {
			return a
		}
		if _, ok := aliases[a]; ok {
			return a
		}
	}
	return ""
}
