# SAT 2.0 Migration

## What Changed

- The canonical executable moved from `wantod/sat.sh` to root `sat.sh`.
- The monolith was split into Bash domain modules, a Python server, and static browser assets.
- `portable` now creates a non-destructive backup. `move` performs backup followed by explicit local deletion.
- `--secret VALUE`, `--token VALUE`, token URL parameters, and password environment values are no longer accepted.
- Not-found, conflict, validation, and authentication failures now return non-zero exit codes.

## Why

Process arguments, URLs, logs, and persistent browser storage are inappropriate places for OTP credentials. Destructive export also made a successful archive operation unnecessarily dangerous.

## How to Migrate

- Replace `wantod/sat.sh` calls with `./sat.sh`.
- Replace `--secret VALUE` with a hidden prompt, `--secret-stdin`, or `--payload-stdin`.
- Replace network `--token VALUE` with `SAT_WEB_TOKEN_FD`.
- Replace destructive `portable` automation with `move --yes` only after reviewing the new backup path.
- Update automation to handle exit codes 2–8 and JSON error objects.

## Compatibility Window

The encrypted `otp.vault` format and primary command names remain compatible throughout SAT 2.x. Legacy scripts remain in `wantod/` as rollback references but receive no fixes.

## Verification and Rollback

Run `./tests/integration.sh`, then point `SAT_HOME` at a copy of the real runtime and verify `list`, `code`, `backup`, and web startup. Roll back by invoking `wantod/sat.sh` against the unchanged vault format. Do not overwrite the v2 source with the legacy copy.
