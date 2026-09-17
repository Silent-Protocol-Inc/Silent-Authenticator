# Repository Guidelines

## Project Structure & Module Organization

- `sat.sh` is the canonical executable and command dispatcher; it only sources `lib/*.sh` and calls `main`.
- `lib/common.sh` owns config/env defaults; `lib/vault.sh` owns locking and OpenSSL encryption; `lib/commands.sh` owns the `cmd_*` handlers; `lib/totp.py` computes TOTP codes.
- `web/server.py` is a thin HTTP transport: it spawns `sat.sh` via `run_cli` and maps the CLI exit code to an HTTP status. Vault policy stays in Bash; never move decisions into Python.
- `web/static/index.html` carries an inline theme-bootstrap `<script>`; `app.js`/`styles.css` are external.
- `tests/` has disposable checks; `docs/` records security, design, and migration contracts; `decisions/ADR-001` explains the security-boundary split.
- This working copy is NOT a git checkout (no `.git`). Root `*.gpg`, `spm_recovery_private.pem`, and `wantod/` are legacy/offline material; treat them as unreadable bytes—never open or test against them.

## Build, Test, and Development Commands

- `./sat.sh doctor` checks dependencies; `./sat.sh help` lists commands.
- `SAT_HOME=/tmp/sat-dev SAT_MASTER_PASS_FD=3 ./sat.sh init 3<<<'dummy-password'` creates a disposable vault.
- `bash -n sat.sh lib/*.sh` and `shellcheck -x sat.sh` must both finish clean.
- `python3 -m py_compile lib/totp.py web/server.py` checks the Python side.
- `./tests/integration.sh` runs CRUD, backup/restore, API, header, and injection regressions; `./tests/load_400.sh` exercises list/bulk-code with 400 entries.
- `python3 tests/test_totp.py` and `python3 tests/verify_design.py` check RFC 6238 vectors and the browser security/design contract.

## Coding Style & Naming Conventions

Use Bash with `set -euo pipefail`, tabs, quoted expansions, `cmd_*` command names, and lower_snake_case helpers. Python is standard-library-first with type hints. Render untrusted JS data with `textContent` or DOM methods—never `innerHTML` or HTML interpolation; `verify_design.py` fails the build if those appear. CSS uses `--sat-*` semantic tokens.

UI copy is Indonesian by default (`SAT_LANG=id`); `t()` in `lib/common.sh` localizes only a handful of IDs, so new copy is usually a literal Indonesian string in `commands.sh`. When you add copy, supply the English variant too. New errors need a stable machine code, actionable message, and documented exit status.

## Cross-File Coupling & Gotchas

- **Exit codes are a contract.** Documented mapping (2 usage, 3 auth, 4 not found, 5 conflict, 6 validation, 7 missing dependency, 8 operational): `web/server.py` maps them to HTTP statuses and `integration.sh` asserts several. Never renumber them.
- **Version bumps are centralized.** `VERSION` is the canonical SemVer source; `lib/common.sh` reads it for CLI and Web UI output, while `integration.sh` checks it dynamically. Update README/CHANGELOG release copy when bumping it.
- **The CSP script hash is content-derived.** `server.py` `end_headers()` pins `sha256-OP4N4…` to the inline `<script>` in `index.html` (verified). Editing that inline script requires regenerating the hash: `python3 -c 'import hashlib,base64; …'` over the script body; otherwise the browser blocks it. `style-src 'self'` forbids inline styles.
- **Secrets never go in argv.** The CLI rejects `--secret VALUE` and `--token VALUE` with `insecure_argument`. Use `--secret-stdin`/`--payload-stdin` and the `SAT_MASTER_PASS_FD`/`SAT_WEB_TOKEN_FD` descriptors. The web server feeds fds 3/4 via pipes; `integration.sh` asserts no password/token/secret in server argv or environ.

## Testing Guidelines

Use `SAT_HOME` under `/tmp` and dummy credentials. `integration.sh` spawns foreground/background web servers on PIDs-derived ephemeral ports and verifies CSP/no-store headers, 403 cross-origin, 413 oversized payload, 401 token gate, and port-conflict exit 8. Cover invalid input, duplicates, wrong passwords, archive verification, XSS, unauthorized APIs, and non-local binding. Never test against `~/.sat` or the root `*.gpg`/`*.pem` files.

## Commit & Pull Request Guidelines

Use short imperative subjects such as `Harden web token handling`. PRs must describe behavior and security changes, migration impact, commands run, and rollback steps. Include responsive screenshots when visual behavior changes. Do not commit vaults, backup ZIPs, logs, PID files, private keys, or real OTP material.

## Security & Configuration Tips

Passwords, web tokens, and OTP secrets must not appear in argv, URLs, logs, fixtures, or browser storage. Preserve localhost-only defaults, require authentication for network binding, validate archive paths, and keep vault writes locked (flock) and atomic (encrypt to `*.new.*`, then `mv`).
