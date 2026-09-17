# Contributing to SAT

## Development

`main` is the stable branch. Work from a focused branch such as `fix/web-hostname-isolation` or `feature/terminal-ux-i18n`; do not commit implementation work directly to `main`. Keep vaults, tokens, private keys, backup archives, and local SAT runtime data outside Git. Use a disposable `SAT_HOME` under `/tmp` for tests.

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

SAT uses Semantic Versioning: PATCH is a compatible fix, MINOR is a compatible feature, and MAJOR is a deliberate compatibility break. Record work under `## [Unreleased]`, classify it, then update `VERSION` and move the actual notes into a dated `CHANGELOG.md` section.

Every release, including PATCH releases, follows this order: branch → tests and documentation → PR to `main` → CI success → approved merge → release skill → annotated `vX.Y.Z` tag → GitHub Release → verification. Never push implementation directly to `main`, force-push a stable branch/tag, tag unmerged work, or bypass failing CI. See [docs/RELEASING.md](docs/RELEASING.md) for the mandatory release checklist and rollback guidance.
