#!/usr/bin/env bash
set -euo pipefail

# PM2 starts this wrapper. Secrets are decrypted into anonymous descriptors only;
# they are never added to PM2's environment, argv, or log stream.
sat_root="$1"; sat_home="$2"; host="$3"; port="$4"; domain="${5:-}"
key_file="$sat_home/sat-web-restart.key"
credential_file="$sat_home/sat-web-restart.enc"
[[ -r "$key_file" && -r "$credential_file" ]] || { printf 'SAT PM2 credentials are unavailable.\n' >&2; exit 78; }

payload="$(openssl enc -d -aes-256-cbc -pbkdf2 -md sha256 -pass "file:$key_file" -in "$credential_file")"
master_password="${payload%%$'\n'*}"
remainder="${payload#*$'\n'}"
web_token="${remainder%$'\nSAT_END'}"
[[ -n "$master_password" && "$remainder" == *$'\nSAT_END' ]] || { printf 'SAT PM2 credentials are invalid.\n' >&2; exit 78; }

server=(python3 "$sat_root/web/server.py" --host "$host" --port "$port" --script "$sat_root/sat.sh" --sat-home "$sat_home" --version "$(<"$sat_root/VERSION")" --password-fd 3 --token-fd 4)
[[ -z "$domain" ]] || server+=(--allowed-host "$domain")
exec "${server[@]}" 3< <(printf '%s\n' "$master_password") 4< <(printf '%s\n' "$web_token")
