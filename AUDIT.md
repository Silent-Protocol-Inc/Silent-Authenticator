# Repository Audit — 2026-09-17

## Scope

Audited the complete active SAT tree: Bash entry point and modules, Python TOTP and HTTP transport, static web UI, tests, documentation, launcher, and ADR. Legacy `wantod/` and root encrypted/offline material were intentionally not opened, per repository policy.

## Findings repaired

- The HTTP per-client limiter retained an unbounded map of client addresses. It now has a 2,048-client ceiling and reclaims expired buckets before admitting a new client. This prevents trivial memory growth on public bindings while retaining the existing 120 requests/minute policy.
- `web-stop` previously removed lifecycle files even if the SAT child still survived `SIGTERM`. It now returns operational exit code `8` and preserves the lifecycle state for investigation when the child remains alive.
- Added server transport regressions for bounded rate limiting, TOTP URI parsing, and the CSP hash that authorizes the inline theme bootstrap.
- QR input copy now matches the GIF format accepted by the server. A failed browser `FileReader` operation is handled as a normal localized error instead of producing an unhandled promise rejection.
- Firefox headless inspection at 390×844 found no clipping or overlap. Its navigation exposed undersized touch targets, so layout-adapter links now use the shared 44px control height on compact screens and the design test enforces it.
- **Hostname isolation:** `spm.erpan.click` had an enabled legacy vhost that proxied to the same `127.0.0.1:8787` origin as SAT. When SAT was running, Nginx correctly selected the SPM vhost but its stale upstream served SAT. SAT's own vhost was already exact and not a default server; certificates were also single-host. The stale SPM enabled symlink was removed (its source file remains recoverable), setup now rejects an origin port claimed by another enabled proxy, and domain-mode SAT rejects non-matching `Host` headers.
- Updated the design document to describe the implemented semantic tokens, ten appearance/layout modes, responsive fallback, and harmless-only preference persistence.

## Verification

Passed on 2026-09-17:

```text
bash -n sat.sh lib/*.sh
shellcheck -x sat.sh
python3 -m py_compile lib/totp.py web/server.py
python3 tests/test_totp.py
python3 tests/test_server.py
python3 tests/verify_design.py
./tests/integration.sh
./tests/load_400.sh
```

## Remaining limits

SAT deliberately remains a single-user, local-first tool. Its compatibility vault uses OpenSSL AES-256-CBC with PBKDF2, its web process retains the master password while running, and QR scanning depends on the optional `zbarimg` binary. These operational limits are documented in `docs/SECURITY.md`.
