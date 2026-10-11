# Harness: Codex

Read at launch with the contract and the goal. Self-contained for Codex.

## Launch

The launch file's first line is the command; the message follows it:

    cmd: codex -m gpt-6.1-sol -c model_reasoning_effort=high
    You are the root. Read $PROTOCOL_SOURCE/sources/loop/contract.md, $PROTOCOL_SOURCE/sources/loop/harness-codex.md
    and <abs goal path> in full. Write <abs report path> as the terminal action.

- The root runs `gpt-6.1-sol` at high.
- Follow the contract's relaunch rule using the full launch message; this harness has no ops grants.
- Check the launch's `Standing:` file with `shasum -a 256`; a mismatch means none and a `judgement`.
- The plugin's Stop hook arms on "You are the root" plus one report path. It releases a stop only for
  a counting report or a current `PAUSED:` line. **Nothing wakes a Codex root that ends its turn**, so
  `WAITING:` releases nothing: hold the turn with `collaboration.wait_agent` until the report is
  written.
- `loop-state` is on `PATH`. Append every event yourself, `dispatch` and `return` included.
- There is no ops lane on Codex: nothing binds an ops grant. Live work stays with the root.

## Routes

| Role | Spawn | Model / effort |
|---|---|---|
| implementation (default) | `lane-worker` | `gpt-6.1-sol` / medium |
| mechanical, tightly specified | generic | `gpt-6.1-sol` / low |
| retry | `lane-worker-retry` | `gpt-6.1-sol` / high |
| cross-file or judgement | `complex-worker` | `gpt-6.1-sol` / high |
| rescue, rung 1; rung 2 | generic | `gpt-6-astra` / medium; `gpt-6-astra` / high |
| escalation (opt-in) | `super-worker` | `gpt-6-astra` / high |
| escalation (owner-named) | `megasuper-worker` | `gpt-6-astra` / xhigh |
| security review | `security-reviewer` | `gpt-6.1-sol` / high |
| review | `reviewer`; complex decisions generic | `gpt-6-luna` / high; `gpt-6.1-sol` / high |
| gate | generic | `gpt-6.1-sol` / low |
| one root-owned watch | `poller` | `gpt-6-luna` / high |
| read-only map | generic | `gpt-6.1-sol` / low; deep synthesis medium |

- Spawn a custom agent by `agent_type` only when its installed pin matches its row; pass no model or
  effort to it. Otherwise spawn generic with explicit `model` and `reasoning_effort`. A spawn with
  neither inherits the root's route.
- Luna is never the root or a writing agent; it may poll and review. The high review route is
  generic `gpt-6.1-sol` / high. Astra: rescue, and the SUPER/MEGASUPER rows under the planner rule.
- The ladder: worker, retry worker, rescue rung 1 (Astra/medium), then rung 2 (Astra/high) only
  after rung 1 fails. There is no root rescue. Each worker gets exactly its one pre-granted attempt.

## Dispatch

- `collaboration.spawn_agent`, `wait_agent`, `list_agents`, `send_message`, `followup_task` and
  `interrupt_agent` are direct calls only; they are not listed inside an exec cell, and that absence
  does not mean dispatch is unavailable.
- Prepare a lane's worktree and packet in one exec cell; the next call is a direct `spawn_agent`.
- Context scope is `fork_turns`: `"none"` with the complete brief (the default for every lane), a
  small positive number only for recent decisions a lane needs, `"all"` almost never. A full-history
  fork inherits the root's route and cannot be routed cheaper.
- 19 child threads plus the root. When lanes may delegate, start at most 12 and keep 7 in reserve.
  Depth is not enforced, so every brief says whether the lane may delegate; Luna never does.
- Never conclude dispatch is unavailable without a recorded `spawn_agent` error. A thread-pool limit
  means wait for a return, then retry. Any other error: retry once; an error tied to the lane's
  arguments or route parks that lane. The same unrelated error on two lanes is resource exhaustion.
  A spawn error consumes no attempt.

## Waits

- `LOOP.md`'s optional `ci-status` replaces `gh` CI waits/reads: substitute the exact full SHA for
  every `{sha}` and poll the one-shot command in the repo cwd in a background `until` loop
  (a yielded foreground exec session, never `&`). Stop on combined `success` or `failure`, not exit 0;
  unknown/missing stays `pending`. Bound reads and the loop by `ci-max-minutes` (default 30),
  sleep 60 s between reads. Deadline means "not observed"; transport/auth errors are unreadable.
  A poller's readback quotes raw command output and SHA instead of `gh run view`.
  Lanes use the same loop in the process-wait cell below. Without the key, GitHub is unchanged.
- With lanes in flight and no local work, make one `collaboration.wait_agent` call. Every wait lasts
  19 minutes (`min_wait_timeout_ms` is 1140000) unless a child finishes or messages first.
- **Returns arrive in context, not in the wait.** A child's `FINAL_ANSWER` lands in context when it
  finishes; a later `wait_agent` reports nothing and blocks the full 19 minutes. Before every wait,
  process each return in context the log does not yet show. After compaction, reconcile
  `list_agents` against `loop-state digest` before the first wait.
- `functions.wait` collects an exec cell, never an agent; `clock.sleep` is never a wait.
- On a timeout, reconcile once (`list_agents`, deadlines), then wait again.
- Process waits (CI, a gate, a release) run in one self-polling exec cell, so the model wakes only
  when the process ends or the cell yields:

```js
// @exec: {"yield_time_ms": 1140000, "max_output_tokens": 400}
const deadline = Date.now() + DEADLINE_MS; // at most 1080000
let r = await tools.exec_command({cmd: "WATCH_COMMAND", yield_time_ms: 1000, max_output_tokens: 200});
while (r.exit_code === undefined && r.session_id !== undefined && Date.now() < deadline) {
  r = await tools.write_stdin({session_id: r.session_id, chars: "", yield_time_ms: 30000, max_output_tokens: 200});
}
text(JSON.stringify({exit_code: r.exit_code ?? null, session_id: r.session_id ?? null, output: r.output}));
```

  `WATCH_COMMAND` is one quiet process that exits on the terminal state, for example
  `gh run watch <id> --exit-status --interval 60 > /dev/null 2>&1; echo exit=$?`. If the cell returns
  still running, rerun it from `let r = {session_id: <id>};`. Lanes wait on their own CI this way.
- A root with lanes in flight cannot wait in a cell: it hands a process wait to a `poller` with the
  exact identity and a deadline. A deadline exit means "not observed".
- Clock gates: prefer removing the gate (trigger or reschedule the job) where authorised. Otherwise
  hold the turn with `wait_agent` and act on the first return after the gate time.

## Long-lived processes

- A process backgrounded with `&`, `nohup` or `disown` from a returning exec call dies with it. Start
  a watcher as a foreground `exec_command` with `yield_time_ms` 1000 and no `&`, and record its
  `session_id`. Never `setsid`: it escapes closeout.
- The session belongs to the thread that started it; a poller cannot `write_stdin` to the root's.

## Recovery

- Compaction may be native and encrypted or a text summary; record which only when the runtime shows
  it. Either way, read `loop-state digest <log>` and continue from it.
- Provider errors are not terminal: recover in the same session under the contract's relaunch rule,
  reconcile children/watchers and the state digest, record the error as a `judgement`, and continue.
  Keep admission, amendments, attempts and owner-control state; never launch a fresh root yourself.
- A requested read-only sandbox is not proof of isolation; a broader parent policy may widen it.

## Closeout sweep

Send `write_stdin` `"\u0003"` to every watcher session still running and record its exit code.
`interrupt_agent` every live poller. List both in the report.
