# Dependency-driven coding loops

A curated, harness-neutral sourcebook for dependency-driven coding loops and selective
fan-out, with profiles for Codex, Claude Code and pi.

- [Protocol](fan-out-protocol.md): authority, bounded lanes, evidence, review and recovery.
- [Backlog board setup](docs/backlog-board-setup.md): tracker setup and migration.

Installation-specific organisations, private repositories and credential locations are
replaced with neutral examples. Work context denotes a work environment, not a particular
employer or customer. Paths beginning with `$` are operator-supplied locations.
The sourcebook includes illustrative local fleet procedures; adapt them to your own
infrastructure. No publication, drift, notification or reconciliation tooling is included.

This tree is a standalone export with fresh history, not a mirror of the source repository.
Only these documents, this README, the Apache-2.0 licence and leak-gate configuration are included.
Source revisions and redaction audits are retained outside the public tree.

## Leak gates

Install `just`, Python 3, TruffleHog and gitleaks. Supply the reviewed `bin/leak-scan`
from an agent-history checkout as `LEAK_SCANNER` (an absolute path). Supply a private
labelled denylist with `LEAK_TERMS_FILE`; never commit that file or print its terms.
`just check` runs tree and complete-history denylist scans, then offline secret scans.
A missing private list or missing scanner is an error, never a clean scan.
TruffleHog verification is disabled so these gates do not contact credential providers.

These checks must pass before sharing an export. No gate publishes anything.
