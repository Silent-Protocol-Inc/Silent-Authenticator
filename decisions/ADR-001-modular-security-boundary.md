# ADR-001: Split the monolith at the security boundary

Date: 2026-08-24
Status: accepted

## Context

The legacy script combined encryption, commands, HTTP transport, CSS, HTML, and JavaScript. Web requests spawned CLI commands with credentials in process-visible channels, while browser rendering mixed untrusted vault labels into HTML strings.

## Options Considered

1. Patch the embedded server and template in place.
2. Rewrite the complete product in a new runtime and migrate the vault.
3. Preserve the Bash CLI and vault format while extracting cohesive modules and a narrow Python transport.

## Decision

Choose option 3. Bash remains the compatibility and policy boundary. Python owns TOTP calculation and HTTP transport. Static browser assets own presentation. Credentials cross process boundaries only through inherited descriptors.

## Consequences

The architecture is easier to test and CSP can be enforced without inline exceptions. Two runtimes remain necessary, and the server still holds the master password in memory while unlocked.

## Validation

Syntax, lint, integration, API security, contrast, and static XSS checks are release gates. The legacy script remains available as rollback evidence.
