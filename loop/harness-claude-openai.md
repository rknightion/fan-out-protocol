# Harness: claude-openai

Read at launch with the contract and the goal. Self-contained for Claude Code running on GPT models
through a LiteLLM gateway, in its own `~/.claude-openai` home.

## Launch

The launch file's first line is the command; the message follows it:

    cmd: claude-openai --model lane-main
    You are the root. Read $PROTOCOL_SOURCE/sources/loop/contract.md, $PROTOCOL_SOURCE/sources/loop/harness-claude-openai.md
    and <abs goal path> in full. Write <abs report path> as the terminal action.

- The root runs `gpt-6.1-sol` at high. The home's lane table sets both for `lane-main`; no flag
  sets them.
- Follow the contract's relaunch rule; this harness supports a bare launch file path, not ops grants.
- Check the launch's `Standing:` file with `shasum -a 256`; a mismatch means none and a `judgement`.
- Same `agent-workflows` plugin, Stop hook and `loop-state` as Claude Code. The hook arms on "You
  are the root" plus exactly one `codex/report-...-loop<N>.md` path, or a bare path to a launch
  file holding them.
- `loop-state` is on `PATH`. Append every event yourself, `dispatch` and `return` included.
- There is no ops lane: nothing binds an ops grant. A lane cannot clear a permission block the root
  could, so SSH, deploys, tenant or cloud mutations, secret-store writes and destructive git stay
  with the root. A lane whose granted push is blocked returns its candidate, and the root lands it.
- Auto mode runs Claude Code's own classifier.

## Routes

sol = `gpt-6.1-sol`, luna = `gpt-6-luna`, astra = `gpt-6-astra`. Each pin and generic `model:` tier
is a gateway lane that fixes its model and effort.

| Role | `subagent_type` | Model / effort |
|---|---|---|
| implementation | `agent-workflows:lane-worker` | sol / medium |
| mechanical, tightly specified | generic, `model: sonnet` | sol / medium |
| cross-file or judgement | `agent-workflows:complex-worker` | sol / medium |
| mapping, complete retrieval | `agent-workflows:mapper` | sol / low |
| gate | `agent-workflows:gate-runner` | sol / low |
| one root-owned watch | `agent-workflows:poller` | luna / high |
| read-only lookup or search | generic, `model: haiku`; `Explore` | luna / high |
| review | `agent-workflows:reviewer` | luna / high |
| security review | `agent-workflows:security-reviewer` | sol / high |
| rescue, rung 1 | `agent-workflows:rescue-specialist` | astra / medium |
| rescue, rung 2 | generic, `model: fable` | astra / high |
| escalation (owner-named) | `agent-workflows:megasuper-worker` | astra / xhigh |
| design decision; high review | the root, or generic `model: opus` | sol / high |

- Never pass `model` to a pinned agent: it overrides the pin's lane.
- `effort` is not an `Agent` parameter. Effort comes only from the lane table: `/effort` does not
  change a lane. Always pass `model` on a generic spawn.
- Luna never writes and is never the root: `model: haiku`, `Explore`, `poller` and `reviewer` take
  read-only work only. The high review route is generic `model: opus`.
- Astra: rescue, and MEGASUPER only for a task the owner named in `## Decisions`. No SUPER route.
- If an `agent-workflows:*` type is missing, the plugin is not installed: harness fault; park the
  lane `needs=defect`, no substitute.
- The ladder: `lane-worker` (2 attempts; the second is the retry), `rescue-specialist` (rung 1),
  then generic `model: fable` (rung 2) only after rung 1 fails. There is no root rescue. A
  `complex-worker` lane has the same 2.
- Gate classification: the root classifies small output itself; one `reviewer` classifies output that
  would flood its context. One fallback per gate run.

## Dispatch

- Dispatch unnamed. A `name:` makes the agent a teammate that goes idle, and its return arrives late
  through the teammate channel.
- Never `subagent_type: "fork"` for a lane: it copies the whole conversation at the root's lane.
- At most 20 running subagents; the 21st fails with `Concurrent subagent limit reached`. Do not
  retry it: wait for a return. When lanes may delegate, start at most 13 and keep 7 in reserve.
- Subagents may nest 3 deep, so a brief must say when a lane may not delegate. `complex-worker`
  delegates only when its brief allows it.
- `isolation: "worktree"` branches from the default branch, not the root's `HEAD`: commit
  prerequisites to the base first.
- WebSearch is denied in this home: search with the Firecrawl MCP (`firecrawl_search`). WebFetch
  works.

## Waits

- `LOOP.md`'s optional `ci-status` replaces `gh` CI waits/reads: substitute the exact full SHA for
  every `{sha}` and poll the one-shot command in the repo cwd in a background `until` loop
  (`run_in_background`). Stop on combined `success` or `failure`, not exit 0; unknown/missing stays
  `pending`. Bound each read and the loop by `ci-max-minutes` (default 30), sleep 60 s between reads.
  A deadline means "not observed"; transport/auth errors are unreadable, never a CI conclusion.
  A poller's readback quotes the command's raw output and SHA instead of `gh run view`.
  Lanes use the same loop within their bounded foreground wait. Without the key, GitHub is unchanged.
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
- The context window is 872k tokens and auto-compact fires at 741,200, leaving the root a text
  summary. After compaction, run `loop-state digest <log>` and continue from it.
- Provider and gateway errors are not terminal: recover in the same session under the contract's
  relaunch rule, reconcile lanes/watchers and the state digest, record the error as a `judgement`,
  and continue. Keep admission, amendments, attempts and owner-control state; never launch a fresh
  root yourself.
- The Stop hook re-prompts a root that ends its turn without a counting report, a current `PAUSED:`
  or a valid `WAITING: ... until <deadline>`, at most three times in one chain; then it allows the
  stop and writes an incident. A new launch re-arms it.

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
