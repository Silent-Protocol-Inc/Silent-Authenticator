# Security Model

SAT protects OTP secrets at rest with the existing OpenSSL AES-256-CBC PBKDF2 vault format. The decrypted document exists only in a mode-0600 temporary file and is removed on process exit. Mutations take an exclusive lock and replace the encrypted vault atomically.

Master passwords, OTP secrets, and web tokens are read from hidden prompts, standard input, or inherited file descriptors. They are not supported as ordinary command arguments. The web server passes the master password to short-lived CLI processes through a pipe descriptor, not argv or environment values.

The web surface defaults to localhost. Network binding requires a token, and SAT sends a default-deny CSP, no-store caching, same-origin resource policy, origin checks for writes, request limits, and per-client rate limiting. The browser keeps the access token in memory only. Vault data is inserted with DOM text APIs.

Domain deployment keeps the same network-token boundary. Cloudflare modes are operator metadata used to validate the selected HTTP port and print DNS pointing guidance; SAT does not modify DNS, firewall, TLS, or Cloudflare settings. A proxied DNS record is not a substitute for authenticated TLS between Cloudflare and the origin.

## Operator Responsibilities

- Protect the operating-system account and `SAT_HOME` permissions.
- Use TLS through a trusted reverse proxy for remote access.
- Keep backup ZIPs protected; encryption strength still depends on the master password.
- Review logs and process ownership before exposing the service.
- Treat a compromised endpoint as able to capture codes while SAT is unlocked.

## Known Limits

The master password remains in web-server memory while the service runs. SAT has no multi-user authorization, audit ledger, hardware-backed key storage, or built-in TLS. Clipboard contents may be observable by other desktop applications. OpenSSL `enc` does not provide modern authenticated encryption; compatibility is preserved in version 2, with a versioned authenticated vault format reserved for a future migration.
