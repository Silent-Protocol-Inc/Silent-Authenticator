# Changelog

All notable changes to SAT are documented here. SAT follows Semantic Versioning.

## [Unreleased]

## [1.4.1] - 2026-09-22

### Fixed

- Select an available high localhost origin port automatically in the HTTPS-domain wizard, with a visible Yes/No confirmation and a manual-port fallback.
- Render confirmation prompts to the terminal while preserving machine-readable Yes/No values for the caller.

## [1.4.0] - 2026-09-22

### Added

- Run every background SAT Web UI instance through PM2 and install a user-specific systemd restore unit on first production start.
- Add an encrypted, mode-`0600` PM2 restart credential bundle that is passed to the Web UI only through inherited file descriptors.
- Extend English terminal feedback for common OTP, validation, and Website errors without removing the SAT ASCII banner.

### Fixed

- Remove failed PM2 starts from the saved process list so a port-conflict process cannot keep restarting.
- Route PM2 stdout and stderr to the SAT Web UI log and remove persistent restart credentials when the Web UI is stopped.

### Security

- Verify PM2-managed Web UI processes do not expose the master password or Web UI token in argv or environment values.

## [1.3.2] - 2026-09-17

### Fixed

- Show the language selector before every interactive terminal menu, while retaining the stored choice and explicit `SAT_LANG` automation override.

## [1.3.1] - 2026-09-17

### Fixed

- Restored the SAT ASCII banner in the interactive terminal menu.

## [1.3.0] - 2026-09-17

### Added

- Added first-run terminal language selection and a persisted English/Bahasa Indonesia preference for interactive menus.
- Added a structured HTTPS domain setup flow with address/DNS/security/TLS sections and a secret-free confirmation summary.

### Changed

- Standardized interactive yes/no parsing, port retry behavior, compact terminal hierarchy, and release governance around PRs and green CI.

## [1.2.0] - 2026-09-17

### Added

- Added ten adaptive Appearance layouts that share SAT's functional core while varying navigation, workspace composition, density, and responsive behavior.

### Fixed

- Isolated SAT Web UI hostname routing so an unrelated enabled Nginx vhost cannot share SAT's origin port.
- Rejected domain setup when another enabled Nginx vhost already proxies to the requested SAT origin.
- Handled QR file-read failures as localized browser errors.

### Security

- Added domain-mode HTTP `Host` validation as defense in depth.
- Added regression coverage for exact, replacement, and unrelated hostnames.

### Changed

- Established `VERSION` as the canonical release version source.

## [2.1.0]

### Added

- Modular local-first SAT CLI, encrypted vault, optional Web UI, and domain deployment workflow.

### Fixed

- Fixed SAT Web UI hostname isolation where a stale, unrelated Nginx vhost could proxy to the same local SAT origin.
- Hardened generated domain deployments to use only the explicit hostname, never a wildcard or default server.
- Refused domain setup when another enabled Nginx vhost already proxies to the requested SAT origin port.
- Added HTTP `Host` validation as defense-in-depth for domain-mode SAT and regression coverage for exact, replacement, and unrelated hostnames.
