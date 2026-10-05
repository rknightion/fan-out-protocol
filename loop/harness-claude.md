# Harness: Claude Code

Read at launch with the contract and the goal. Self-contained for Claude Code.

## Launch

The launch file's first line is the command; the message follows it:

    cmd: claude --model claude-opus-5-5 --effort high
    You are the root. Read $PROTOCOL_SOURCE/sources/loop/contract.md, $PROTOCOL_SOURCE/sources/loop/harness-claude.md
    and <abs goal path> in full. Write <abs report path> as the terminal action.

- The root runs Opus 5.5 at `high`, set on the `cmd:` line. Never a newer model or a higher effort.
- Follow the contract's relaunch rule; this harness supports a bare launch file path, not ops grants.
- The plugin's Stop hook arms on "You are the root" plus exactly one `codex/report-...-loop<N>.md`
  path, or a bare path to a launch file holding them.
- `loop-state` is on `PATH`. Append every event yourself, `dispatch` and `return` included.
- There is no ops lane on Claude Code: nothing binds an ops grant. A lane cannot clear a permission
  block the root could, so SSH, deploys, tenant or cloud mutations, secret-store writes and
  destructive git stay with the root. A lane whose granted push is blocked returns its candidate,
  and the root lands it.

## Routes

The `agent-workflows` plugin ships pinned agents; a pin is the only way to give a dispatch an effort
different from the root's.

| Role | `subagent_type` | Model / effort |
|---|---|---|
| single-fact lookup, self-evidently right or wrong | generic, `model: haiku` | Haiku |
| mapping; retrieval where completeness matters | `agent-workflows:mapper` | Sonnet / low |
| gate | `agent-workflows:gate-runner` | Sonnet / low |
| one root-owned watch | `agent-workflows:poller` | Sonnet / low |
| implementation | `agent-workflows:lane-worker` | Sonnet / high |
| cross-file or judgement | `agent-workflows:complex-worker` | Opus / high |
| review | `agent-workflows:reviewer` | Opus / medium |
| security review | `agent-workflows:security-reviewer` | Opus / high |
| rescue | `agent-workflows:rescue-specialist` | Opus / high |
| design decision | the root, or generic `model: opus` | Opus at the root's effort |

- Never pass `model` to a pinned agent: it overrides the pin.
- `effort` is not an `Agent` parameter. A generic spawn runs at the root's effort.
- If an `agent-workflows:*` type is missing, the plugin is not installed: dispatch generically with
  the table's model and record that the lane ran at the root's effort.
- The ladder: `lane-worker` (2 attempts), root rescue (1), `rescue-specialist` (1). A
  `complex-worker` lane has the same 2; the root's rescue applies only when it has a concrete
  correction the worker lacked.
- Gate classification: the root classifies small output itself; one `reviewer` classifies output that
  would flood its context. One fallback per gate run.

## Dispatch

- Dispatch unnamed. A `name:` makes the agent a teammate that goes idle, and its return arrives late
  through the teammate channel.
- Never `subagent_type: "fork"` for a lane: it copies the whole conversation at the root's model.
- At most 20 running subagents; the 21st fails with `Concurrent subagent limit reached`. Do not
  retry it: wait for a return. When lanes may delegate, start at most 13 and keep 7 in reserve.
- Subagents may nest 3 deep, so a brief must say when a lane may not delegate.
- `isolation: "worktree"` branches from the default branch, not the root's `HEAD`: commit
  prerequisites to the base first.
- `Workflow` runs a frozen topology as a script, but only when the owner's own launch message opts in
  ("use a workflow"). It caps concurrency at `min(16, CPUs - 2)`, queues the excess and forbids
  nesting.

## Waits

- A lane's completion arrives as a task notification. That is the lane wait.
- The root's own wait (landing CI, a release) is one `run_in_background` Bash command whose `until`
  loop exits on every terminal state; its completion wakes the session. Streamed events use
  `Monitor`, which expires after 30 minutes and is re-armed.
- A wait neither can express goes to a `poller` with the exact identity, terminal conditions and a
  deadline. Its return must quote the raw readback (`gh run view <id> --json
  headSha,status,conclusion`); without it, read the run yourself before acting.
- Never a foreground `sleep` over 60 seconds.
- Ending the turn while background work runs is the wait: end it with a `WAITING:` line.
- A lane waits on its own CI with a foreground bounded wait (`gh run watch --exit-status`) inside the
  Bash tool's 10-minute timeout, re-invoked on expiry.

## Timeouts, retries and recovery

- Bash calls time out at 10 minutes; run anything longer with `run_in_background`.
- Compaction leaves a text summary, and Opus gets no remaining-context signal. After compaction, run
  `loop-state digest <log>` and continue from it.
- Provider errors are not terminal: recover in the same session under the contract's relaunch rule,
  reconcile lanes/watchers and the state digest, record the error as a `judgement`, and continue.
  Keep admission, amendments, attempts and owner-control state; never launch a fresh root yourself.
- The Stop hook re-prompts a root that ends its turn without a counting report, a current `PAUSED:`
  or a valid `WAITING: ... until <deadline>`, at most three times in one chain; then it allows the
  stop and writes an incident. A new launch re-arms it.
- The local watchdog alerts on a dead loop (no report or marker, and no new turn for 15 minutes). It
  never resumes or kills anything.

## Closeout sweep

Stop every poller and background watcher the run started, and list them in the report.

## Turn endings

```text
## TURN ENDINGS: a message with no tool call stops the run

A message with no tool call ends your turn, and the loop stops there until the operator returns.
Four endings stop a run while work is still owed; do not use any of them:
1. A summary of what was done that announces the next step without taking it.
2. An offer to carry on unless the operator would prefer otherwise.
3. A list of decisions when, by your own account, none of them blocks the remaining work.
4. Deciding this is a good place to report because the turn was long or a milestone is done.
Status notes and recommendations are welcome: put them in the same message as your next tool call
and continue with whatever does not depend on an answer. End a turn only when the run-end report is
written and pinged, when paused, or when you are waiting on a running background command or monitor
that will wake this session. When waiting, make the last line `WAITING: <what> until <YYYY-MM-DDTHH:MM[:SS]Z>`. When paused, make it `PAUSED: <reason>`. Never TaskStop a subagent mid-mutation.
This does not override confirmation for risky or destructive actions.
```
