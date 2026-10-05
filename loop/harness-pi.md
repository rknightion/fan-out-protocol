# Harness: pi

Read at launch with the contract and the goal. Self-contained for pi.

## Runtime

- Models: `gpt-6.1-sol`, `gpt-6-luna` and `gpt-6-astra` only, through codex-lb. Any other model, and
  any model override on `subagent`, is blocked.
- Launchers: Personal `loop-pi`, Work `work-pi`, Fast `loop-pi-fast` only;
  `loop-pi-dispatch[-variant]` starts a dispatcher root. `-fast` sets priority at launch, not authority.

## Launch

- Launch `loop-pi[-variant] --thinking medium`; the root runs `gpt-6.1-sol`.
  The owner's message names the contract, this harness, goal and terminal report, plus any
  `Ops grants:` / `Audit grants:` file and sha256.
- Launch preflights and snapshots remote audit. Before cross-repo dispatch run
  `loop-pi-preflight <repo>` and `loop-pi-audit add <repo>`; refusal parks.
- Follow the contract's relaunch rule. Continuation arms on "You are the root" plus one report path,
  or a launch file path. It refuses a wrong host/repository, missing run dir, changed opening goal hash
  or launch grant paths/hashes disagreeing with the goal's Authority. It freezes `Ops grants:` and
  `Audit grants:` after file/hash checks; rejection means no grants and an incident. A first goal-only
  input warns it did not arm. Existing `open` is retained; same-session resume restores
  persisted launch authority, never infers it from the goal or later grant-file edits.

## Dispatch

- One async `subagent` `{agent, task}` per lane with the contract's brief. No workflow (blocked),
  model/thinking/deadline override or mid-run tool enabling; `subagent` is present from turn one.
- loop-state appends `dispatch` and `return` from the brief and run id. Watch/heartbeat events are
  automatic (below); append the other events yourself. A missing return block gets one package-owned
  resume, correlated to the original lane/run; refusal or another missing block records failure once.
- Only `-push` agents may `git push`, never with force. Ops rights come from the `ops` agent plus
  `Ops surface:`; the guard binds the surface and refuses a second ops run on it.
- 19 root async slots, depth 2; only `complex-worker` may get delegation. Reserve 7 slots for it.
- Worktree isolation branches from `HEAD`, requiring a clean checkout; candidate/branch worktrees
  remain until land or park.

## Routes

| Role | Agent | Model / thinking |
|---|---|---|
| implementation (default) | `lane-worker`, `lane-worker-push` | sol / medium |
| mechanical, tightly specified | `lane-worker-low`, `lane-worker-low-push` | sol / low |
| retry | `lane-worker-retry`, `lane-worker-retry-push` | sol / high |
| cross-file or judgement | `complex-worker`, `complex-worker-push` | sol / high |
| rescue | `rescue-sol`; `rescue-astra` | sol / high; astra / medium |
| security review | `security-reviewer` | sol / high |
| review | `reviewer`; `reviewer-high` | sol / medium; sol / high |
| gate | `gate-runner` | sol / low |
| ops; read-only probe | `ops`; `ops-probe` | sol / high; sol / low |
| triage of a failed return | `triager` | sol / medium |
| read-only map | `mapper`; `mapper-deep` | luna / medium; sol / medium |

- Luna never writes or roots; Astra is rescue-only. Ladder: worker, `lane-worker-retry`, root rescue,
  one `rescue-sol` or `rescue-astra`. Missing agents are harness faults: park, never substitute.

## Waits

- Push wakes: lane return, `watch_start` exit or `wake_at`; no wait tool. Process every return,
  append its events, then `WAITING: <what> until <deadline>`. Continuation requires a timer at or
  before that deadline and arms one if none exists.
- Lane timers are automatic: loop-wait arms one per lane at the brief's `Deadline:` or the run
  deadline and cancels it when the lane returns. Do not arm lane timers yourself.
- Root CI/release waits use `watch_start`: one quiet command exiting on every terminal state,
  deadline no later than the wait. No root `watch_process` while lanes are live.
- Clock gates: arm `wake_at` for the gate time, end with `WAITING:`, act on the wake.
- Lanes wait on their own CI with `watch_process` (`deadline_s` up to 3600), re-invoked on expiry.
- With no live lane, admissible work or armed wait, continuation nudges closeout instead of WAITING.
- Automatic `watch` rows cover process watchers and wake timers, including lane/continuation timers.
  `what` is `watch <id>: <label>` or `wake <id>: <reason>`; stop reuses that instance and exact ISO
  deadline. Stops cover completion, deadline, cancel, closeout, orderly shutdown and reconciliation,
  regardless of wake delivery. Delivery is causal per instance: an unacknowledged start and successors
  stay in a durable outbox; its stop waits for start acknowledgement. Restart/later lifecycle retries
  without idle polling; exact-event deduplication handles a lost acknowledgement, not reusable labels.
  Other instances proceed independently.
- Armed-root turn/tool activity and assistant message end emit `heartbeat {at}`: first activity, then
  at least 300 seconds after the last recorded heartbeat, across restart. No idle timer; startup,
  notifications and receipt polls do not count, and backward clocks are suppressed.

## Timeouts, retries and recovery

- Children die at agent `timeoutMs` (workers 4 h), steered to checkpoint 10 minutes before.
- Provider retries last about an hour; 300 s silent streams retry. Exhaustion is infrastructure,
  not an attempt. Root request-ceiling aborts get at most two re-prompts.
- pi compacts near a full window by summary, injecting the state digest there and at session start.
  Continue from it; context size never justifies closeout.
- Provider/harness errors are not terminal. Recover in the same session per the contract; re-probe
  lanes/watchers, record error class and idle interval as a `judgement`, then continue. Never reset
  admission, attempts or owner-control state.
- A failed child-guard registration blocks `subagent`: a harness fault; park the run.

## Declared heavy gates

Only unfenced `- gate: <name> | <exact command>` under `LOOP.md`'s `## Mutexes` is authoritative;
prose/examples are advisory. Case-sensitive names match `[A-Za-z0-9][A-Za-z0-9._-]{0,127}`; command
is the trimmed remainder after the first `|`. Malformed/duplicate names or commands fail closed.
Use direct `loop-gate-lock <name>` only: no cwd/env prefix, wrapper, chain, pipe or redirection.
The guard-owned cwd/exact LOOP.md hash bind approval; model binding flags fail.
The CLI executes under a kernel lock for one OS account on one machine across homes/repos/worktrees,
not HOME or lock-dir overrides; unsafe ownership/permissions fail closed. Declared `git push` or
`gh pr merge` (including recognized wrappers) is refused: remote moves need separate audited bash.
Concealed task-runner/script behavior is not newly detected; this is an honest-mistake fence.

## Guard fences

- Every role: background launches (`&`, `nohup`, `disown`, `setsid`), force and destructive pushes, `git add -A`, `git commit -a`, and
  the shared Backlog and staging guards.
- Root also: harness `--by` values, run-dir and authority-registry writes, a second `subagent` status
  poll between wakes, `bash` timeouts over 900 s.
- Lanes also: secret-store writes, `gh release create|edit|delete`, `gh pr merge`, `gh workflow run`,
  mutating `gh api`, and edits to `codex/ops-*`, `codex/state-*`, `codex/goal-*` and
  `codex/grants-*`. An ops lane may run what its surface entry allows.
- Foreground nested children inherit their parent's push grant.
- The guard catches honest mistakes; the closeout audit is the evidence of remote changes.

## Closeout sweep

1. Stop remaining async runs through `subagent`; retry once if shutting down; list unstoppable runs.
2. `/loop-closeout` stops watchers, cancels timers and audits. Non-zero is not clean: report every
   ungranted change.

## Turn endings

```text
## TURN ENDINGS: a message with no tool call stops the run

A message with no tool call ends your turn. Four endings stop a run while work is still owed; do
not use any of them:
1. A summary of what was done that announces the next step without taking it.
2. An offer to carry on unless the operator would prefer otherwise.
3. A list of decisions when, by your own account, none of them blocks the remaining work.
4. Deciding this is a good place to report because the turn was long or a milestone is done.
Status notes and recommendations are welcome: put them in the same message as your next tool call
and continue with whatever does not depend on an answer. End a turn only when the run-end report is
written and pinged, when paused, or when a lane, a `watch_start` watcher or a `wake_at` timer will
wake this session. When waiting, make the last line
`WAITING: <what> until <YYYY-MM-DDTHH:MM[:SS]Z>` with a future deadline; arm `wake_at` for it
first. When paused, make it `PAUSED: <reason>`. Never poll `subagent` status between wakes.
Launch each lane as its own `subagent` call. Give any `bash` call that can run past 15 minutes a
`timeout`, or run it under `watch_start`: the watchdog reads a longer silent turn as stalled.
This does not override confirmation for risky or destructive actions.
```
