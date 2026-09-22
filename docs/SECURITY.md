# Security Model

## Supported Versions

Security fixes are applied to the current 2.1.x release line. Check [CHANGELOG.md](../CHANGELOG.md) before reporting an issue to confirm the installed version.

## Reporting a Vulnerability

Do not disclose exploitable vulnerabilities, vault material, passwords, tokens, private keys, or recovery data in public issues. Use GitHub's private security-advisory reporting for the repository when available, or contact the repository owner through an existing private channel. Include reproducible, sanitized steps and the affected SAT version.

SAT protects OTP secrets at rest with the existing OpenSSL AES-256-CBC PBKDF2 vault format. The decrypted document exists only in a mode-0600 temporary file and is removed on process exit. Mutations take an exclusive lock and replace the encrypted vault atomically.

Master passwords, OTP secrets, and web tokens are read from hidden prompts, standard input, or inherited file descriptors. They are not supported as ordinary command arguments. The web server passes the master password to short-lived CLI processes through a pipe descriptor, not argv or environment values.

The web surface defaults to localhost. Network binding requires a token, and SAT sends a default-deny CSP, no-store caching, same-origin resource policy, origin checks for writes, request limits, and per-client rate limiting. The browser keeps the access token in memory only. Vault data is inserted with DOM text APIs.

Domain deployment keeps the same network-token boundary while binding SAT only to loopback. nginx terminates public HTTPS and proxies to SAT; Certbot's `dns-cloudflare` plugin creates and validates ACME TXT records. Each generated SAT vhost has one exact `server_name`, never a wildcard or `default_server`. Setup refuses an origin port already referenced by another enabled Nginx proxy, and the SAT HTTP transport also rejects a mismatched `Host` header. This prevents another hostname sharing the same IP, Cloudflare zone, or certificate infrastructure from becoming an alias for SAT. The Cloudflare API token is stored mode `0600` at `$SAT_HOME/cloudflare.ini` so Certbot renewal can reuse it. Scope that token to the intended zone with only `Zone > Zone > Read` and `Zone > DNS > Edit`. A proxied record means Cloudflare terminates TLS at its edge and can observe Web UI content; use DNS-only mode when Cloudflare is outside the trust boundary.

## Operator Responsibilities

- Protect the operating-system account and `SAT_HOME` permissions.
- Use TLS through a trusted reverse proxy for remote access.
- Keep backup ZIPs protected; encryption strength still depends on the master password.
- Review logs and process ownership before exposing the service.
- Treat a compromised endpoint as able to capture codes while SAT is unlocked.

## Known Limits

The master password remains in web-server memory while the service runs. For PM2-backed background Web UI, SAT also retains a mode-`0600` encrypted restart bundle and a separate mode-`0600` key in `SAT_HOME`; this is required for unattended restart after reboot and is deleted by `web-stop`. It protects against other local users, but not a compromise of the SAT operating-system account or root. SAT has no multi-user authorization, audit ledger, hardware-backed key storage, or built-in TLS. Clipboard contents may be observable by other desktop applications. OpenSSL `enc` does not provide modern authenticated encryption; compatibility is preserved in version 2, with a versioned authenticated vault format reserved for a future migration.
