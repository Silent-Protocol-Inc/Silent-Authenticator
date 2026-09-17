# Contributing to SAT

## Development

Work from a focused branch such as `fix/web-hostname-isolation` or `feature/qr-import`. Keep vaults, tokens, private keys, backup archives, and local SAT runtime data outside Git. Use a disposable `SAT_HOME` under `/tmp` for tests.

Run the release checks before proposing a change:

```bash
bash -n sat.sh lib/*.sh
shellcheck -x sat.sh
python3 -m py_compile lib/totp.py web/server.py
python3 tests/test_totp.py
python3 tests/test_server.py
python3 tests/verify_design.py
./tests/integration.sh
./tests/load_400.sh
```

## Commits and Pull Requests

Use Conventional Commit subjects, for example `fix(web): isolate hostname routing` or `docs: clarify vault recovery`. Describe behavior, security impact, tests run, and rollback considerations. Include responsive screenshots for visual changes.

## Releases

SAT uses Semantic Versioning. Record work under `## [Unreleased]` in `CHANGELOG.md`; PATCH is for compatible fixes, MINOR for compatible features, and MAJOR for intentional breaking changes. For a release: update `VERSION`, move notes into the dated release section, run every check above, commit with `chore(release): prepare vX.Y.Z`, annotate `vX.Y.Z`, then push `main` and the tag. Never force-push a stable branch or release tag.
