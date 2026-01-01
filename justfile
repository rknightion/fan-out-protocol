set shell := ["bash", "-euo", "pipefail", "-c"]

# List supported tasks.
default:
    @just --list

# Verify the local offline scanning toolchain and private denylist.
setup:
    @command -v python3 git trufflehog gitleaks >/dev/null; test -f "${LEAK_SCANNER:?set LEAK_SCANNER}"; test -f "${LEAK_TERMS_FILE:?set LEAK_TERMS_FILE}"

# Format the task interface.
[group('check')]
fmt:
    just --fmt

# Check task interface formatting.
[group('check')]
fmt-check:
    just --fmt --check

# Check export whitespace.
[group('check')]
lint:
    git show --check --format= HEAD

# Scan the complete tree and fresh history without provider verification.
[group('check')]
test: setup
    python3 "${LEAK_SCANNER}" --root . --path .
    python3 "${LEAK_SCANNER}" --root . --history
    trufflehog git "file://$PWD" --no-verification --no-update --fail --fail-on-scan-errors --concurrency 2
    gitleaks git . --redact --no-banner --timeout 120

# Run all local export gates; never publish.
[group('check')]
check: fmt-check lint test
