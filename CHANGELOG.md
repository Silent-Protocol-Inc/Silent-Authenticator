# Changelog

All notable changes to SAT are documented here. SAT follows Semantic Versioning.

## [Unreleased]

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
