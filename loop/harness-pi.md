# Harness: pi

Read contract/goal.

## Runtime

- Only codex-lb `gpt-6.1-sol`, `gpt-6-luna`, `gpt-6-astra`; block other models/subagent overrides.
- Personal `loop-pi`, Work `work-pi`, Fast `loop-pi-fast` (priority only);
  dispatcher `loop-pi-dispatch[-variant]`.

## Launch

- `loop-pi[-variant]`, root `gpt-6.1-sol` / high by default. Owner names contract/harness/goal,
  terminal report, any `Ops grants:`/`Audit grants:`/`Standing:` file/sha256.
- Launch preflights/snapshots audit. Cross-repo needs `loop-pi-preflight <repo>` and
  `loop-pi-audit add <repo>`; refusal parks.
- Follow the contract's relaunch rule. Continuation arms on "You are the root" plus one report/launch path.
  Wrong host/repo, missing run dir, changed goal hash or grant path/hash mismatch with Authority
  refuse. Freeze all three after file/hash checks (`Standing:`: `$LOOP_PI_RUN_DIR/standing.md`);
  rejection grants nothing: incident. Goal-only warns. Keep `open`; resume restores authority,
  never infers from goal/grant edits.

## Dispatch

- One async `subagent` `{agent, task}` per lane with contract brief, turn one. No workflow,
  model/run-deadline override (guard), thinking override (policy) or mid-run tool enabling.
- loop-state records brief/run `dispatch`/`return`, watch/heartbeat; append others yourself.
  Missing return: one package-owned original-lane/run resume; refusal/repeat records failure once.
- Only `-push` lanes may push, never force. Ops: `ops` plus `Ops surface:`; guard binds surface,
  refusing a second ops run there.
- 19 async slots, depth 2; delegate only to `complex-worker`, reserve 7.
- `returns candidate` per contract; goal conflicts: `loop-lint` G14.
- Isolation needs clean `HEAD`. Named lanes: retained cwd/native `worktree:false`.
  Completion/reload keeps trees; land/park/closeout removes only verified clean terminal trees.
  Dirty/live/unknown stays; integrate before removal.
- Native/default validates full binary base-to-tree patch with untracked files before tree/branch
  deletion. Copy `worktree-diffs` on completion/startup/shutdown to `$LOOP_PI_RUN_DIR/lane-patches/`:
  exact-run/lane/task, content hashes; survives tree/scratch deletion, no upstream prune-hook API.
  Verification, missing capture and cleanup: contract sections 5 and 8.

## Routes

| Role | Agent | Model / thinking |
|---|---|---|
| implementation | `lane-worker(-push)` | sol / medium |
| mechanical | `lane-worker-low(-push)` | sol / low |
| retry | `lane-worker-retry(-push)` | sol / high |
| judgement | `complex-worker(-push)` | sol / high |
| rescue | `rescue-astra-medium`; `rescue-astra` | astra / medium; astra / high |
| SUPER; MEGASUPER | `super-worker(-push)`; `megasuper-worker(-push)` | astra / high; astra / xhigh |
| security review | `security-reviewer` | sol / high |
| review | `reviewer`; `reviewer-high` | luna / high; sol / high |
| gate | `gate-runner` | sol / low |
| ops; read-only probe | `ops`; `ops-probe` | sol / medium; sol / low |
| return triage | `triager` | sol / medium |
| read-only map | `mapper`; `mapper-deep` | sol / low; sol / medium |

- Luna reviews but never writes/roots. Astra: rescue, SUPER, MEGASUPER (planner rule, cap 2/1).
  Ladder: worker, `lane-worker-retry`, `rescue-astra-medium`, then `rescue-astra` if it fails; no
  root rescue. High review: `reviewer-high`. Missing agent: harness fault; park, no substitute.

## Waits

- `LOOP.md`'s optional `ci-status`: replace each `{sha}` with exact full SHA; poll in repo cwd in a background
  `until` loop via `watch_start`, never `&`; lanes use `watch_process`. Combined `success`/`failure`
  ends it, not exit 0; unknown/missing: `pending`. Bound reads/loop by `ci-max-minutes` (default 30);
  sleep 60 s. Deadline: "not observed"; transport/auth: unreadable. Poller quotes raw output/SHA,
  not `gh run view`.
- Wakes: lane return, `watch_start` exit, `wake_at`; no wait tool. Process returns/events, then end
  `WAITING: <what> until <deadline>`; continuation arms a timer for it.
- Idle lane-return `Subagent updates above.`: package wake, not owner control.
- loop-wait arms lane `Deadline:`/run-deadline timers, cancels on return; never arm them yourself.
- Esc holds fired `watch`/`wake` deliveries (persisted) until the owner's next turn ends;
  request-ceiling aborts are not held.
- Root CI/release: bounded quiet `watch_start`, all terminal states; no live-lane `watch_process`.
- Clock gates: `wake_at` at gate, end `WAITING:`, act on wake.
- Lane CI: `watch_process`, `deadline_s` <=3600; re-invoke on expiry.
- Automatic `watch`: process/wake timers including lane/continuation. `what`: `watch <id>: <label>`
  or `wake <id>: <reason>`. Stop reuses instance/ISO deadline on completion, deadline, cancel,
  closeout, shutdown/reconciliation regardless of delivery. Delivery is causal per instance:
  durable start before stop; restart retries without polling. Dedup handles lost acknowledgements.
- Armed-root turn/tool activity/message end: `heartbeat {at}` first, then >=300 seconds apart across
  restart. No idle timer; startup/notifications/receipt polls don't count; no backward clocks.

## Timeouts, retries and recovery

- Children die at `timeoutMs` (workers 4 h); checkpoint 10 min before.
- Provider retries: one unresettable 20 min episode; 300 s silence retries. Exhaustion:
  infrastructure, no attempt. Root request-ceiling aborts: <=2 re-prompts.
- Compaction/start injects state digest: continue.
- Provider/harness errors: in-session recovery, re-probe lanes/watchers, record class/idle interval
  as `judgement`. Never reset admission, attempts or owner controls.
- Child-guard failure blocks `subagent`: harness fault; park.

## Heavy gates

Only unfenced `- gate: <name> | <exact command>` under `LOOP.md` `## Mutexes` grants authority.
Names: case-sensitive `[A-Za-z0-9][A-Za-z0-9._-]{0,127}`; trim after first `|`.
Malformed/duplicate names/commands fail closed. Direct `loop-gate-lock <name>` only: no cwd/env
prefix, wrapper, chain, pipe/redirection. Binds guard-owned cwd/exact LOOP.md hash; model flags fail.
Kernel lock: one OS account on one machine across homes/repos/worktrees; not HOME/lock-dir overrides;
unsafe ownership/permissions fail closed. Declared `git push`/`gh pr merge`, recognized wrappers
included, refuses: separate audited bash.

## Guard fences

- Block `&`, `nohup`, `disown`, `setsid`, force/destructive pushes, `git add -A`, `git commit -a`;
  Backlog/staging guards apply to all.
- Root: harness `--by`, run-dir/authority-registry writes, second `subagent` status poll between
  wakes, `bash` timeouts >900 s.
- Lanes block secret-store writes, `gh release create|edit|delete`, `gh pr merge`, `gh workflow run`,
  mutating `gh api`, edits to `codex/{ops,state,goal,grants}-*`. Ops permits only its surface entry.
- Nested foreground children inherit parent push. Guard: mistake fence; audit: remote evidence.

## Closeout sweep

1. Stop async `subagent` runs; retry once if shutting down; list unstoppable runs.
2. After reviewed land, only the root publishes: before audit, its `bash` runs
   `git push origin main` (actual branch). `push-log.jsonl` receipts the full old/new range, including
   publication before a board-only tip, from successful Git porcelain even if later shell work fails.
   Skipped/rejected/no-op grants nothing. Named remote: identical fetch/push endpoint matching
   audit snapshot. Exact endpoint (SSH user included), repo/config/env bind execution;
   absolute/alias/command/env Git wrappers fail closed for root attribution.
3. After publication, `/loop-closeout` stops watchers/timers and audits. Nonzero is not clean;
   report ungranted changes. Never rewrite evidence. Of root scratch it deletes only registered
   clean landed worktrees and `disposable` dirs: `scratch_register` each one (`keep` carries it).
   `<run dir>/teardown.json` lists the rest.

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
