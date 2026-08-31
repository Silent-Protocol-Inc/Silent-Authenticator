# Repository Guidelines

## Project Structure & Module Organization

- `sat.sh` is the canonical executable and command dispatcher.
- `lib/` owns configuration, encrypted storage, CLI behavior, and RFC 6238 TOTP generation.
- `web/server.py` provides local HTTP transport; browser assets live in `web/static/`.
- `tests/` contains disposable checks; `docs/` records security, design, and migration contracts.

## Build, Test, and Development Commands

- `./sat.sh doctor` checks the runtime and dependencies; `./sat.sh help` lists commands.
- `SAT_HOME=/tmp/sat-dev SAT_MASTER_PASS_FD=3 ./sat.sh init 3<<<'dummy-password'` creates a disposable vault.
- `bash -n sat.sh lib/*.sh` performs Bash syntax checks.
- `shellcheck -x sat.sh` follows sourced modules and must finish without findings.
- `./tests/integration.sh` runs CRUD, backup/restore, API, header, and injection regressions using dummy data only.
- `./tests/load_400.sh` exercises list and bulk-code behavior with 400 generated entries.
- `python3 tests/test_totp.py` checks RFC 6238 SHA-1 vectors.
- `python3 tests/verify_design.py` verifies design tokens, contrast, CSP compatibility, and prohibited browser patterns.

## Coding Style & Naming Conventions

Use Bash with `set -euo pipefail`, tabs, quoted expansions, `cmd_*` command names, and lower_snake_case helpers. Python is standard-library-first with type hints. Render untrusted JavaScript data with `textContent` or DOM methods—never HTML interpolation. CSS uses `--sat-*` semantic tokens.

Maintain Indonesian and English UI copy together. New errors need a stable machine code, actionable message, and documented exit status.

## Testing Guidelines

Use `SAT_HOME` under `/tmp` and dummy credentials. Cover invalid input, duplicates, wrong passwords, archive verification, XSS, unauthorized APIs, and non-local binding. Never test against `~/.sat` or repository vaults.

## Commit & Pull Request Guidelines

Use short imperative subjects such as `Harden web token handling`. PRs must describe behavior and security changes, migration impact, commands run, and rollback steps. Include responsive screenshots when visual behavior changes. Do not commit vaults, backup ZIPs, logs, PID files, private keys, or real OTP material.

## Security & Configuration Tips

Passwords, web tokens, and OTP secrets must not appear in argv, URLs, logs, fixtures, or browser storage. Preserve localhost-only defaults, require authentication for network binding, validate archive paths, and keep vault writes locked and atomic.
