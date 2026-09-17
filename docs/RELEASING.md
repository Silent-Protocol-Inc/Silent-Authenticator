# Releasing SAT

## Version classification

SAT follows Semantic Versioning. Use PATCH for compatible fixes, MINOR for compatible user-facing features, and MAJOR only for intentional compatibility breaks. `VERSION` is the only canonical runtime version; update the dated section of `CHANGELOG.md` at release preparation.

## Mandatory workflow

1. Create a `feature/*`, `fix/*`, `refactor/*`, `docs/*`, or `security/*` branch from current `main`.
2. Implement, document, and run the complete verification suite with disposable data only.
3. Create a pull request targeting `main`. Its description must state the version classification, compatibility/security impact, tests, and rollback path.
4. Wait for every required CI check to pass. Fix failures on the same branch; never bypass a failed or pending check.
5. Merge through the repository-approved method (squash is preferred for focused work). Do not push implementation directly to `main`.
6. After merge, load and follow the available release skill. Verify the worktree, canonical version, changelog, merged commit, and absent tag before creating annotated `vX.Y.Z` and the matching GitHub Release.
7. Fetch tags and verify the release URL, tag target, and `main` commit. Delete the merged feature branch when no longer needed.

## Safety and rollback

Never include vaults, tokens, private keys, logs, or backup archives. Do not retag published releases. If a released regression is found, prepare a new PATCH PR; retain the prior GitHub Release and document the rollback/recovery instructions in the corrective PR.
