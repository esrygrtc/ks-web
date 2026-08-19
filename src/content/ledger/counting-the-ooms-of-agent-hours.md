---
title: "Counting the OOMs of agent-hours"
date: "2026-08-20"
draft: true
standfirst: "The industry is scaling agent labor by orders of magnitude while the hours themselves stay disposable. A durable session turns compute time from a consumable into an asset, and the difference decides who pays for the same work twice."
---

The industry has quietly settled on a new unit of work. An agent that spends an afternoon migrating a codebase is not a stream of requests and it is not a bag of tokens. It is agent-hours: long, stateful, interruptible labor that behaves less like an API call and more like an employee's shift. Compute used to be billed in requests, then in tokens. It is now billed in this.

And everyone's plan for that unit is the same plan: add zeros. More agents per team, longer tasks per agent, more of the loop handed over. Roadmaps are written in orders of magnitude · OOMs of agent-hours, scaled the way we once scaled requests per second.

The pun in the title is deliberate. The industry counts its OOMs of growth in a unit that still dies, routinely, to the other kind of OOM.

## How an agent-hour dies

A long-running agent lives inside infrastructure that was built for stateless tenants. The kernel OOM-kills its container because something else on the box got greedy. A deploy rolls the fleet, and the agent's process goes with it. The spot instance it was priced onto is preempted with a warning too short to use. None of this is exotic. It is the ordinary weather of running compute cheaply, and stateless services shrug it off by design.

An agent does not shrug. It dies mid-shift with the dev server warm, the test suite half run, files edited but not committed, and a working model of the codebase that took the whole session to build. Its transcript may survive. The world it was standing in does not.

## The bill is paid twice

When that happens, the meter does not rewind. You already paid for every token that built the agent's position, and the position is gone. So you pay again: the restarted agent re-reads the repository, re-installs the dependencies, re-runs the tests, re-derives the plan, and only then returns to the point of failure. The first bill bought work. The second bill buys back ground the first bill had already bought.

For one agent this is an annoyance. Multiply it by the OOMs everyone intends and it becomes a structural tax: some fraction of all agent labor, forever, spent recomputing state that existed an hour ago. Scaling a consumable just scales the waste with it.

## A consumable, or an asset

The alternative is to make the session durable: checkpoint the whole machine · filesystem, memory, running processes · so that an interruption is a pause, not a reset. That changes the category of the thing you bought. A consumable is spent and gone. An asset persists, can be set down, picked up, moved, and returned to. Checkpointed compute time is an asset: the afternoon of work is a thing you hold, not a thing that happened.

This is easy to assert and it is the kind of assertion that should not be trusted without measurement, including from us. So here is what our gates measured, on the record at [/proof](/proof):

- Durability as a rate, not an anecdote: [25 of 25 fresh kill-and-resume cycles, with a Wilson 95% CI of [86.7%, 100.0%]](/proof) · the interval stated because 25 trials cannot honestly carry more than that.
- The storage cost of checkpointing often enough to matter: [82 checkpoints held 4,233 MiB against a naive 80,952 MiB · 19.1x dedup](/proof), because an agent touches a small fraction of its machine per step.
- The second agent, reported as data rather than claimed: for aider 0.86.2 the gateway [held the exactly-once door 4 of 4 runs, and the agent walked through it 3 of 4](/proof). We publish the walk rate instead of rounding it up.

The bench behind those numbers is one Mac Mini, and we say so on the proof page. What holds there is what we claim · nothing about production scale is being asserted here.

## The unit needs an owner

Every prior unit of compute got a meter, and the meter got a company. Requests had one. Tokens had one. Agent-hours do not, and the gap shows: frameworks orchestrate the hour, sandboxes host it, nothing keeps it. A unit of labor that evaporates on contact with a deploy is not really a unit yet · it is an accident that usually goes your way.

We think the durable session is the primitive the agent economy gets built on, for a plain reason: it is the smallest thing that makes an agent-hour survivable, portable, and therefore ownable. Once the hour is an object · checkpointed, resumable, forkable · it can be priced as what it is, and the double bill stops being a cost of doing business and becomes a defect you fixed.

That is the frame we call the Session Economy: durable sessions as the unit of agent labor, and the state they carry treated as the asset it already is. The industry will keep adding zeros either way. The question is whether the hours under those zeros are things you keep or things you burn.

This essay is part of The Session Economy series · one email per essay, and you can subscribe on [the Ledger index](/ledger/).
