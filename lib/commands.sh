#!/usr/bin/env bash

set_json_output_if_requested() {
	local arg
	for arg in "$@"; do
		[[ "$arg" == '--json' ]] && SAT_OUTPUT='json'
	done
}

print_banner() {
	cat <<'EOF'

          _____                    _____                _____
         /\    \                  /\    \              /\    \
        /::\    \                /::\    \            /::\    \
       /::::\    \              /::::\    \           \:::\    \
      /::::::\    \            /::::::\    \           \:::\    \
     /:::/\:::\    \          /:::/\:::\    \           \:::\    \
    /:::/__\:::\    \        /:::/__\:::\    \           \:::\    \
    \:::\   \:::\    \      /::::\   \:::\    \          /::::\    \
  ___\:::\   \:::\    \    /::::::\   \:::\    \        /::::::\    \
 /\   \:::\   \:::\    \  /:::/\:::\   \:::\    \      /:::/\:::\    \
/::\   \:::\   \:::\____\/:::/  \:::\   \:::\____\    /:::/  \:::\____\
\:::\   \:::\   \::/    /\::/    \:::\  /:::/    /   /:::/    \::/    /
 \:::\   \:::\   \/____/  \/____/ \:::\/:::/    /   /:::/    / \/____/
  \:::\   \:::\    \               \::::::/    /   /:::/    /
   \:::\   \:::\____\               \::::/    /   /:::/    /
    \:::\  /:::/    /               /:::/    /    \::/    /
     \:::\/:::/    /               /:::/    /      \/____/
      \::::::/    /               /:::/    /
       \::::/    /               /:::/    /
        \::/    /                \::/    /
         \/____/                  \/____/

EOF
	printf 'Silent Authenticator Tool (SAT)  v%s  © 2026 SilentProtocol. Licensed under Apache-2.0.\n\n' "$APP_VERSION"
}

cmd_help() {
	printf '%s %s\n\n' "$APP_NAME" "$APP_VERSION"
	cat <<'EOF'
Usage:
  sat.sh init
  sat.sh add [label] [--issuer TEXT] [--account TEXT] [--secret-stdin]
  sat.sh update <label> [--new-label TEXT] [--issuer TEXT] [--account TEXT]
  sat.sh list | search <query> | show <label>
  sat.sh code <label> [--clip] [--live] | codes
  sat.sh delete <label> [--yes]
  sat.sh backup [name] | restore <archive.zip> [--yes]
  sat.sh move [name] [--yes] | portable [name]
  sat.sh doctor | version | menu | help
  sat.sh web [--host 127.0.0.1] [--port 8787]
  sat.sh web-start [web options] | web-stop | web-status
  sat.sh web-public [--port 8787]
  sat.sh web-domain <domain> [--cloudflare off|dns-only|proxied] [--port PORT]

Options:
  --json            Machine-readable output.
  --payload-stdin   Read an add/update JSON object from standard input.
  --secret-stdin    Read one BASE32 secret from standard input.

Environment:
  SAT_LANG=id|en              UI language (default: id).
  SAT_HOME=/path              Runtime directory (default: ~/.sat).
  SAT_VAULT_FILE=/path        Encrypted vault override.
  SAT_MASTER_PASS_FD=N        Read master password from an inherited file descriptor.
  SAT_WEB_TOKEN_FD=N          Read web token from an inherited file descriptor.
  SAT_OUTPUT=text|json        Default output format.

Security:
  Passwords, OTP secrets, and web tokens are not accepted as normal command-line
  values because process arguments may be visible to other software. Network web
  binding requires a token. `portable` is now a safe alias for `backup`; use
  `move` when an encrypted backup should be followed by local vault deletion.
  `web-public` restores direct VPS access with an interactive, memory-only token.
  `web-domain` exposes SAT through a validated domain/subdomain and records its
  DNS/Cloudflare mode. Proxied Cloudflare HTTP defaults to port 8080.
  Use a trusted HTTPS reverse proxy for permanent internet exposure.
EOF
}

cmd_version() {
	if [[ "$SAT_OUTPUT" == 'json' ]]; then
		printf '{"name":"SAT","version":"%s"}\n' "$APP_VERSION"
	else
		printf '%s %s\n' "$APP_NAME" "$APP_VERSION"
	fi
}

cmd_doctor() {
	local name status='ok' missing=0
	if [[ "$SAT_OUTPUT" == 'json' ]]; then
		if ! command -v jq >/dev/null 2>&1; then
			printf '{"status":"degraded","error":"jq_missing","message":"Install jq to use SAT and structured doctor output"}\n'
			return 1
		fi
		local payload='[]'
		for name in bash openssl jq python3 flock zip unzip; do
			if command -v "$name" >/dev/null 2>&1; then
				payload="$(jq -cn --argjson rows "$payload" --arg name "$name" '$rows + [{name:$name,status:"ok"}]')"
			else
				payload="$(jq -cn --argjson rows "$payload" --arg name "$name" '$rows + [{name:$name,status:"missing"}]')"
				missing=1
			fi
		done
		((missing == 0)) || status='degraded'
		jq -cn --arg status "$status" --argjson dependencies "$payload" \
			--arg vault "$SAT_VAULT_FILE" --argjson vault_exists "$([[ -f "$SAT_VAULT_FILE" ]] && printf true || printf false)" \
			'{status:$status,vault:{path:$vault,exists:$vault_exists},dependencies:$dependencies}'
	else
		printf '%-12s %s\n' 'DEPENDENCY' 'STATUS'
		for name in bash openssl jq python3 flock zip unzip; do
			if command -v "$name" >/dev/null 2>&1; then
				printf '%-12s %s\n' "$name" 'ok'
			else
				printf '%-12s %s\n' "$name" 'missing'
				missing=1
			fi
		done
		printf '\nVault: %s (%s)\n' "$SAT_VAULT_FILE" "$([[ -f "$SAT_VAULT_FILE" ]] && printf 'exists' || printf 'missing')"
	fi
	return "$missing"
}

cmd_init() {
	require_cmd openssl
	require_cmd jq
	read_master_pass
	local plain
	plain="$(new_temp_file)"
	printf '{}\n' >"$plain"
	acquire_vault_lock
	if [[ -e "$SAT_VAULT_FILE" ]]; then
		release_vault_lock
		fail 5 'vault_exists' "Vault sudah ada di $SAT_VAULT_FILE."
	fi
	encrypt_file_to_vault "$plain"
	release_vault_lock
	if [[ "$SAT_OUTPUT" == 'json' ]]; then
		jq -cn --arg path "$SAT_VAULT_FILE" '{status:"created",path:$path}'
	else
		printf 'Vault dibuat: %s\n' "$SAT_VAULT_FILE"
	fi
}

read_add_input() {
	local payload_stdin="$1" secret_stdin="$2"
	shift 2
	ADD_LABEL='' ADD_ISSUER='' ADD_ACCOUNT='' ADD_SECRET='' ADD_DIGITS='6' ADD_PERIOD='30' ADD_ALGO='SHA1'
	if [[ "$payload_stdin" == 'yes' ]]; then
		local payload
		payload="$(</dev/stdin)"
		jq -e 'type == "object"' <<<"$payload" >/dev/null || fail 6 'invalid_json' 'Payload JSON tidak valid.'
		ADD_LABEL="$(jq -r '.label // ""' <<<"$payload")"
		ADD_ISSUER="$(jq -r '.issuer // ""' <<<"$payload")"
		ADD_ACCOUNT="$(jq -r '.account // ""' <<<"$payload")"
		ADD_SECRET="$(jq -r '.secret // ""' <<<"$payload")"
		ADD_DIGITS="$(jq -r '.digits // 6' <<<"$payload")"
		ADD_PERIOD="$(jq -r '.period // 30' <<<"$payload")"
		ADD_ALGO="$(jq -r '.algo // "SHA1"' <<<"$payload")"
		return
	fi
	while (($#)); do
		case "$1" in
			--label) [[ $# -ge 2 ]] || fail 2 'usage' '--label membutuhkan nilai.'; ADD_LABEL="$2"; shift 2 ;;
			--issuer) [[ $# -ge 2 ]] || fail 2 'usage' '--issuer membutuhkan nilai.'; ADD_ISSUER="$2"; shift 2 ;;
			--account) [[ $# -ge 2 ]] || fail 2 'usage' '--account membutuhkan nilai.'; ADD_ACCOUNT="$2"; shift 2 ;;
			--digits) [[ $# -ge 2 ]] || fail 2 'usage' '--digits membutuhkan nilai.'; ADD_DIGITS="$2"; shift 2 ;;
			--period) [[ $# -ge 2 ]] || fail 2 'usage' '--period membutuhkan nilai.'; ADD_PERIOD="$2"; shift 2 ;;
			--algo) [[ $# -ge 2 ]] || fail 2 'usage' '--algo membutuhkan nilai.'; ADD_ALGO="${2^^}"; shift 2 ;;
			--secret-stdin) secret_stdin='yes'; shift ;;
			--secret) fail 2 'insecure_argument' 'Gunakan --secret-stdin atau prompt tersembunyi; --secret tidak diterima.' ;;
			--json|--payload-stdin) shift ;;
			-*) fail 2 'usage' "Argumen tidak dikenal: $1" ;;
			*) [[ -z "$ADD_LABEL" ]] || fail 2 'usage' "Argumen berlebih: $1"; ADD_LABEL="$1"; shift ;;
		esac
	done
	if [[ "$secret_stdin" == 'yes' ]]; then
		IFS= read -r ADD_SECRET || true
	fi
	if [[ -t 0 ]]; then
		[[ -n "$ADD_LABEL" ]] || { printf 'Label: ' >&2; IFS= read -r ADD_LABEL; }
		[[ -n "$ADD_ISSUER" ]] || { printf 'Issuer: ' >&2; IFS= read -r ADD_ISSUER; }
		[[ -n "$ADD_ACCOUNT" ]] || { printf 'Account: ' >&2; IFS= read -r ADD_ACCOUNT; }
		if [[ -z "$ADD_SECRET" ]]; then
			printf 'Secret BASE32: ' >&2
			IFS= read -r -s ADD_SECRET
			printf '\n' >&2
		fi
	fi
}

validate_entry() {
	ADD_SECRET="$(normalize_secret "$ADD_SECRET")"
	ADD_ALGO="${ADD_ALGO^^}"
	validate_label "$ADD_LABEL" || fail 6 'invalid_label' 'Label wajib diisi, maksimal 128 karakter, tanpa karakter kontrol.'
	validate_text "$ADD_ISSUER" 256 || fail 6 'invalid_issuer' 'Issuer maksimal 256 karakter tanpa karakter kontrol.'
	validate_text "$ADD_ACCOUNT" 256 || fail 6 'invalid_account' 'Account maksimal 256 karakter tanpa karakter kontrol.'
	validate_secret "$ADD_SECRET" || fail 6 'invalid_secret' 'Secret harus berupa BASE32 valid dengan panjang 8 sampai 1024 karakter.'
	validate_digits "$ADD_DIGITS" || fail 6 'invalid_digits' 'Digits harus bernilai 6 sampai 10.'
	validate_period "$ADD_PERIOD" || fail 6 'invalid_period' 'Period harus bernilai 15 sampai 90 detik.'
	validate_algo "$ADD_ALGO" || fail 6 'invalid_algorithm' 'Algoritma harus SHA1, SHA256, atau SHA512.'
}

cmd_add() {
	set_json_output_if_requested "$@"
	local payload_stdin='no' secret_stdin='no' arg
	for arg in "$@"; do
		[[ "$arg" == '--payload-stdin' ]] && payload_stdin='yes'
		[[ "$arg" == '--secret-stdin' ]] && secret_stdin='yes'
	done
	read_add_input "$payload_stdin" "$secret_stdin" "$@"
	validate_entry
	local plain updated exists
	plain="$(new_temp_file)"; updated="$(new_temp_file)"
	acquire_vault_lock
	decrypt_vault_to "$plain"
	exists="$(jq -r --arg lbl "$ADD_LABEL" 'has($lbl)' "$plain")"
	if [[ "$exists" == 'true' ]]; then
		release_vault_lock
		fail 5 'label_exists' "Label '$ADD_LABEL' sudah ada. Gunakan update."
	fi
	jq --arg lbl "$ADD_LABEL" --arg issuer "$ADD_ISSUER" --arg account "$ADD_ACCOUNT" --arg secret "$ADD_SECRET" \
		--argjson digits "$ADD_DIGITS" --argjson period "$ADD_PERIOD" --arg algo "$ADD_ALGO" \
		'.[$lbl]={issuer:$issuer,account:$account,secret:$secret,digits:$digits,period:$period,algo:$algo}' "$plain" >"$updated"
	encrypt_file_to_vault "$updated"
	release_vault_lock
	if [[ "$SAT_OUTPUT" == 'json' ]]; then
		jq -cn --arg lbl "$ADD_LABEL" --arg issuer "$ADD_ISSUER" --arg account "$ADD_ACCOUNT" \
			--argjson digits "$ADD_DIGITS" --argjson period "$ADD_PERIOD" --arg algo "$ADD_ALGO" \
			'{status:"created",label:$lbl,issuer:$issuer,account:$account,digits:$digits,period:$period,algo:$algo}'
	else
		printf "OTP '%s' disimpan.\n" "$ADD_LABEL"
	fi
}

cmd_list() {
	set_json_output_if_requested "$@"
	local plain
	plain="$(new_temp_file)"
	read_vault "$plain"
	if [[ "$SAT_OUTPUT" == 'json' ]]; then
		jq -c '{entries:(to_entries | sort_by(.key | ascii_downcase) | map({label:.key,issuer:(.value.issuer//""),account:(.value.account//""),digits:(.value.digits//6),period:(.value.period//30),algo:(.value.algo//"SHA1")}))}' "$plain"
	else
		printf '%-24s %-20s %s\n' 'LABEL' 'ISSUER' 'ACCOUNT'
		jq -r 'to_entries | sort_by(.key | ascii_downcase)[] | [.key,.value.issuer,.value.account] | @tsv' "$plain" |
			while IFS=$'\t' read -r label issuer account; do
				printf '%-24s %-20s %s\n' "$label" "$issuer" "$account"
			done
	fi
}

cmd_search() {
	set_json_output_if_requested "$@"
	local query='' arg plain
	for arg in "$@"; do
		[[ "$arg" == '--json' ]] || { [[ -z "$query" ]] && query="$arg"; }
	done
	[[ -n "$query" ]] || fail 2 'usage' 'Usage: sat.sh search <query> [--json]'
	plain="$(new_temp_file)"
	read_vault "$plain"
	if [[ "$SAT_OUTPUT" == 'json' ]]; then
		jq -c --arg q "${query,,}" '{entries:(to_entries | map(select(((.key+" "+(.value.issuer//"")+" "+(.value.account//""))|ascii_downcase|contains($q)))) | map({label:.key,issuer:(.value.issuer//""),account:(.value.account//""),digits:(.value.digits//6),period:(.value.period//30),algo:(.value.algo//"SHA1")}))}' "$plain"
	else
		jq -r --arg q "${query,,}" 'to_entries | map(select(((.key+" "+(.value.issuer//"")+" "+(.value.account//""))|ascii_downcase|contains($q))))[] | [.key,.value.issuer,.value.account] | @tsv' "$plain" |
			while IFS=$'\t' read -r label issuer account; do printf '%-24s %-20s %s\n' "$label" "$issuer" "$account"; done
	fi
}

cmd_show() {
	set_json_output_if_requested "$@"
	local label='' arg plain item
	for arg in "$@"; do [[ "$arg" == '--json' ]] || { [[ -z "$label" ]] && label="$arg"; }; done
	[[ -n "$label" ]] || fail 2 'usage' 'Usage: sat.sh show <label> [--json]'
	plain="$(new_temp_file)"; read_vault "$plain"
	item="$(jq -c --arg lbl "$label" '.[$lbl] // empty' "$plain")"
	[[ -n "$item" ]] || fail 4 'not_found' "Label '$label' tidak ditemukan."
	if [[ "$SAT_OUTPUT" == 'json' ]]; then
		jq -c --arg lbl "$label" '{label:$lbl,issuer:(.issuer//""),account:(.account//""),digits:(.digits//6),period:(.period//30),algo:(.algo//"SHA1")}' <<<"$item"
	else
		jq -r --arg lbl "$label" '["Label   : "+$lbl,"Issuer  : "+(.issuer//""),"Account : "+(.account//""),"Digits  : "+((.digits//6)|tostring),"Period  : "+((.period//30)|tostring)+" detik","Algo    : "+(.algo//"SHA1")] | .[]' <<<"$item"
	fi
}

cmd_update() {
	set_json_output_if_requested "$@"
	local payload_stdin='no' current_label='' new_label='' issuer='__KEEP__' account='__KEEP__' secret='__KEEP__' digits='__KEEP__' period='__KEEP__' algo='__KEEP__'
	local payload
	while (($#)); do
		case "$1" in
			--payload-stdin) payload_stdin='yes'; shift ;;
			--new-label|--rename) [[ $# -ge 2 ]] || fail 2 'usage' '--new-label membutuhkan nilai.'; new_label="$2"; shift 2 ;;
			--issuer) [[ $# -ge 2 ]] || fail 2 'usage' '--issuer membutuhkan nilai.'; issuer="$2"; shift 2 ;;
			--account) [[ $# -ge 2 ]] || fail 2 'usage' '--account membutuhkan nilai.'; account="$2"; shift 2 ;;
			--digits) [[ $# -ge 2 ]] || fail 2 'usage' '--digits membutuhkan nilai.'; digits="$2"; shift 2 ;;
			--period) [[ $# -ge 2 ]] || fail 2 'usage' '--period membutuhkan nilai.'; period="$2"; shift 2 ;;
			--algo) [[ $# -ge 2 ]] || fail 2 'usage' '--algo membutuhkan nilai.'; algo="${2^^}"; shift 2 ;;
			--secret-stdin) IFS= read -r secret || true; shift ;;
			--secret) fail 2 'insecure_argument' 'Gunakan --secret-stdin atau --payload-stdin.' ;;
			--json) shift ;;
			-*) fail 2 'usage' "Argumen tidak dikenal: $1" ;;
			*) [[ -z "$current_label" ]] || fail 2 'usage' "Argumen berlebih: $1"; current_label="$1"; shift ;;
		esac
	done
	if [[ "$payload_stdin" == 'yes' ]]; then
		payload="$(</dev/stdin)"
		jq -e 'type == "object"' <<<"$payload" >/dev/null || fail 6 'invalid_json' 'Payload JSON tidak valid.'
		current_label="$(jq -r '.current_label // ""' <<<"$payload")"
		new_label="$(jq -r '.new_label // .label // ""' <<<"$payload")"
		jq -e 'has("issuer")' <<<"$payload" >/dev/null && issuer="$(jq -r '.issuer // ""' <<<"$payload")"
		jq -e 'has("account")' <<<"$payload" >/dev/null && account="$(jq -r '.account // ""' <<<"$payload")"
		jq -e 'has("secret")' <<<"$payload" >/dev/null && secret="$(jq -r '.secret // ""' <<<"$payload")"
		jq -e 'has("digits")' <<<"$payload" >/dev/null && digits="$(jq -r '.digits' <<<"$payload")"
		jq -e 'has("period")' <<<"$payload" >/dev/null && period="$(jq -r '.period' <<<"$payload")"
		jq -e 'has("algo")' <<<"$payload" >/dev/null && algo="$(jq -r '.algo' <<<"$payload")"
	fi
	[[ -n "$current_label" ]] || fail 2 'usage' 'Usage: sat.sh update <label> [...options]'
	local plain updated item target_label exists
	plain="$(new_temp_file)"; updated="$(new_temp_file)"
	acquire_vault_lock; decrypt_vault_to "$plain"
	item="$(jq -c --arg lbl "$current_label" '.[$lbl] // empty' "$plain")"
	if [[ -z "$item" ]]; then release_vault_lock; fail 4 'not_found' "Label '$current_label' tidak ditemukan."; fi
	target_label="${new_label:-$current_label}"
	validate_label "$target_label" || { release_vault_lock; fail 6 'invalid_label' 'Label baru tidak valid.'; }
	if [[ "$target_label" != "$current_label" ]]; then
		exists="$(jq -r --arg lbl "$target_label" 'has($lbl)' "$plain")"
		[[ "$exists" == 'false' ]] || { release_vault_lock; fail 5 'label_exists' "Label '$target_label' sudah ada."; }
	fi
	[[ "$issuer" == '__KEEP__' ]] && issuer="$(jq -r '.issuer // ""' <<<"$item")"
	[[ "$account" == '__KEEP__' ]] && account="$(jq -r '.account // ""' <<<"$item")"
	[[ "$secret" == '__KEEP__' ]] && secret="$(jq -r '.secret // ""' <<<"$item")"
	[[ "$digits" == '__KEEP__' ]] && digits="$(jq -r '.digits // 6' <<<"$item")"
	[[ "$period" == '__KEEP__' ]] && period="$(jq -r '.period // 30' <<<"$item")"
	[[ "$algo" == '__KEEP__' ]] && algo="$(jq -r '.algo // "SHA1"' <<<"$item")"
	ADD_LABEL="$target_label" ADD_ISSUER="$issuer" ADD_ACCOUNT="$account" ADD_SECRET="$secret" ADD_DIGITS="$digits" ADD_PERIOD="$period" ADD_ALGO="$algo"
	validate_entry
	jq --arg old "$current_label" --arg lbl "$ADD_LABEL" --arg issuer "$ADD_ISSUER" --arg account "$ADD_ACCOUNT" --arg secret "$ADD_SECRET" \
		--argjson digits "$ADD_DIGITS" --argjson period "$ADD_PERIOD" --arg algo "$ADD_ALGO" \
		'del(.[$old]) | .[$lbl]={issuer:$issuer,account:$account,secret:$secret,digits:$digits,period:$period,algo:$algo}' "$plain" >"$updated"
	encrypt_file_to_vault "$updated"; release_vault_lock
	if [[ "$SAT_OUTPUT" == 'json' ]]; then
		jq -cn --arg lbl "$ADD_LABEL" --arg old_label "$current_label" --arg issuer "$ADD_ISSUER" --arg account "$ADD_ACCOUNT" --argjson digits "$ADD_DIGITS" --argjson period "$ADD_PERIOD" --arg algo "$ADD_ALGO" '{status:"updated",label:$lbl,old_label:$old_label,issuer:$issuer,account:$account,digits:$digits,period:$period,algo:$algo}'
	else
		printf "OTP '%s' diperbarui menjadi '%s'.\n" "$current_label" "$ADD_LABEL"
	fi
}

copy_code() {
	local code="$1"
	if command -v wl-copy >/dev/null 2>&1; then printf '%s' "$code" | wl-copy
	elif command -v xclip >/dev/null 2>&1; then printf '%s' "$code" | xclip -selection clipboard
	elif command -v pbcopy >/dev/null 2>&1; then printf '%s' "$code" | pbcopy
	elif command -v termux-clipboard-set >/dev/null 2>&1; then printf '%s' "$code" | termux-clipboard-set
	else return 1
	fi
}

cmd_code() {
	set_json_output_if_requested "$@"
	local label='' clip='no' live='no'
	while (($#)); do
		case "$1" in --json) shift ;; --clip) clip='yes'; shift ;; --live|-l) live='yes'; shift ;; -*) fail 2 'usage' "Argumen tidak dikenal: $1" ;; *) [[ -z "$label" ]] || fail 2 'usage' "Argumen berlebih: $1"; label="$1"; shift ;; esac
	done
	[[ -n "$label" ]] || fail 2 'usage' 'Usage: sat.sh code <label> [--clip] [--live] [--json]'
	[[ "$live" == 'no' || "$SAT_OUTPUT" != 'json' ]] || fail 2 'unsupported' 'Mode live tidak mendukung output JSON.'
	while :; do
		local plain item secret digits period algo result code
		plain="$(new_temp_file)"; read_vault "$plain"
		item="$(jq -c --arg lbl "$label" '.[$lbl] // empty' "$plain")"
		[[ -n "$item" ]] || fail 4 'not_found' "Label '$label' tidak ditemukan."
		secret="$(jq -r '.secret' <<<"$item")"; digits="$(jq -r '.digits // 6' <<<"$item")"; period="$(jq -r '.period // 30' <<<"$item")"; algo="$(jq -r '.algo // "SHA1"' <<<"$item")"
		result="$(printf '%s' "$secret" | python3 "$SAT_ROOT/lib/totp.py" code --digits "$digits" --period "$period" --algorithm "$algo")"
		code="$(jq -r '.code' <<<"$result")"
		if [[ "$SAT_OUTPUT" == 'json' ]]; then jq -c --arg lbl "$label" '. + {label:$lbl}' <<<"$result"
		else printf '\r%-24s %s  %2ss ' "$label" "$code" "$(jq -r '.expires_in' <<<"$result")"; fi
		if [[ "$clip" == 'yes' ]]; then copy_code "$code" || fail 7 'clipboard_unavailable' 'Clipboard helper tidak tersedia.'; clip='no'; fi
		[[ "$live" == 'yes' ]] || { [[ "$SAT_OUTPUT" == 'text' ]] && printf '\n'; break; }
		sleep 1
	done
}

cmd_codes() {
	set_json_output_if_requested "$@"
	local plain result
	plain="$(new_temp_file)"; read_vault "$plain"
	result="$(python3 "$SAT_ROOT/lib/totp.py" codes --vault "$plain")"
	if [[ "$SAT_OUTPUT" == 'json' ]]; then printf '%s\n' "$result"
	else
		printf '%-24s %-12s %-8s %s\n' 'LABEL' 'CODE' 'SISA' 'ISSUER'
		jq -r '.entries[] | [.label,.code,(.expires_in|tostring),.issuer] | @tsv' <<<"$result" |
			while IFS=$'\t' read -r label code remaining issuer; do printf '%-24s %-12s %-8s %s\n' "$label" "$code" "${remaining}s" "$issuer"; done
	fi
}

cmd_delete() {
	set_json_output_if_requested "$@"
	local label='' yes='no'
	while (($#)); do case "$1" in --json) shift ;; --yes|--force) yes='yes'; shift ;; -*) fail 2 'usage' "Argumen tidak dikenal: $1" ;; *) [[ -z "$label" ]] || fail 2 'usage' "Argumen berlebih: $1"; label="$1"; shift ;; esac; done
	[[ -n "$label" ]] || fail 2 'usage' 'Usage: sat.sh delete <label> [--yes] [--json]'
	if [[ "$yes" == 'no' ]]; then
		[[ -t 0 ]] || fail 2 'confirmation_required' 'Gunakan --yes untuk mode non-interaktif.'
		printf "Ketik label '%s' untuk menghapus: " "$label" >&2
		local answer; IFS= read -r answer; [[ "$answer" == "$label" ]] || fail 2 'cancelled' 'Penghapusan dibatalkan.'
	fi
	local plain updated exists
	plain="$(new_temp_file)"; updated="$(new_temp_file)"; acquire_vault_lock; decrypt_vault_to "$plain"
	exists="$(jq -r --arg lbl "$label" 'has($lbl)' "$plain")"
	[[ "$exists" == 'true' ]] || { release_vault_lock; fail 4 'not_found' "Label '$label' tidak ditemukan."; }
	jq --arg lbl "$label" 'del(.[$lbl])' "$plain" >"$updated"; encrypt_file_to_vault "$updated"; release_vault_lock
	if [[ "$SAT_OUTPUT" == 'json' ]]; then jq -cn --arg lbl "$label" '{status:"deleted",label:$lbl}'; else printf "OTP '%s' dihapus.\n" "$label"; fi
}

validate_bundle_name() {
	[[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$ ]] || fail 6 'invalid_bundle_name' 'Nama backup hanya boleh memakai huruf, angka, titik, garis bawah, dan tanda hubung.'
}

cmd_backup() {
	set_json_output_if_requested "$@"
	require_cmd zip
	require_cmd unzip
	require_cmd sha256sum
	local name='' arg staging archive checksum vault_snapshot
	for arg in "$@"; do [[ "$arg" == '--json' ]] || { [[ -z "$name" ]] && name="$arg"; }; done
	name="${name:-sat_backup_$(date -u +%Y%m%dT%H%M%SZ)}"; validate_bundle_name "$name"
	archive="$(pwd -P)/${name}.zip"; [[ ! -e "$archive" ]] || fail 5 'target_exists' "Target sudah ada: $archive"
	staging="$(new_temp_dir)"; mkdir -p "$staging/$name/lib" "$staging/$name/web/static" "$staging/$name/docs"
	vault_snapshot="$staging/$name/otp.vault"
	acquire_vault_lock
	if [[ ! -f "$SAT_VAULT_FILE" ]]; then release_vault_lock; fail 4 'vault_missing' "$(t vault_missing)"; fi
	cp -- "$SAT_VAULT_FILE" "$vault_snapshot"
	SAT_BACKUP_VAULT_SHA256="$(sha256sum "$vault_snapshot" | awk '{print $1}')"
	release_vault_lock
	cp -- "$SAT_ROOT/sat.sh" "$staging/$name/sat.sh"
	cp -- "$SAT_ROOT"/lib/*.sh "$SAT_ROOT"/lib/*.py "$staging/$name/lib/"
	cp -- "$SAT_ROOT"/web/server.py "$staging/$name/web/"; cp -- "$SAT_ROOT"/web/static/* "$staging/$name/web/static/"
	[[ ! -f "$SAT_ROOT/README.md" ]] || cp -- "$SAT_ROOT/README.md" "$staging/$name/"
	[[ ! -f "$SAT_ROOT/docs/SECURITY.md" ]] || cp -- "$SAT_ROOT/docs/SECURITY.md" "$staging/$name/docs/"
	( cd "$staging" && zip -qr "$archive" "$name" )
	unzip -tq "$archive" >/dev/null || fail 8 'backup_verification_failed' 'Arsip backup gagal diverifikasi.'
	checksum="$(sha256sum "$archive" | awk '{print $1}')"
	SAT_BACKUP_PATH="$archive"; SAT_BACKUP_SHA256="$checksum"
	if [[ "${SAT_BACKUP_SILENT:-no}" == 'yes' ]]; then return; fi
	if [[ "$SAT_OUTPUT" == 'json' ]]; then jq -cn --arg path "$archive" --arg sha256 "$checksum" '{status:"created",path:$path,sha256:$sha256,vault_deleted:false}'
	else printf 'Backup dibuat: %s\nSHA-256: %s\nVault lokal tetap tersedia.\n' "$archive" "$checksum"; fi
}

inspect_backup_archive() {
	local archive="$1"
	python3 - "$archive" <<'PY'
import pathlib
import sys
import zipfile

archive = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(archive) as bundle:
    members = bundle.infolist()
    if len(members) > 1000 or sum(item.file_size for item in members) > 50_000_000:
        raise SystemExit(1)
    vaults = []
    for item in members:
        path = pathlib.PurePosixPath(item.filename)
        if path.is_absolute() or ".." in path.parts:
            raise SystemExit(1)
        if len(path.parts) == 2 and path.name == "otp.vault" and item.file_size <= 10_000_000:
            vaults.append(item.filename)
    if len(vaults) != 1:
        raise SystemExit(1)
    print(vaults[0])
PY
}

cmd_restore() {
	set_json_output_if_requested "$@"
	require_cmd unzip
	require_cmd python3
	local archive='' yes='no' arg member='' extracted existing_backup='' restored_temp=''
	for arg in "$@"; do case "$arg" in --json) ;; --yes) yes='yes' ;; *) [[ -z "$archive" ]] && archive="$arg" ;; esac; done
	[[ -f "$archive" ]] || fail 4 'archive_missing' 'Arsip backup tidak ditemukan.'
	unzip -tq "$archive" >/dev/null || fail 6 'invalid_archive' 'Arsip ZIP rusak atau tidak valid.'
	member="$(inspect_backup_archive "$archive")" || fail 6 'invalid_archive' 'Struktur atau ukuran arsip tidak aman.'
	if [[ -e "$SAT_VAULT_FILE" && "$yes" == 'no' ]]; then fail 2 'confirmation_required' 'Vault sudah ada. Gunakan --yes setelah memastikan backup tersedia.'; fi
	extracted="$(new_temp_file)"; unzip -p "$archive" "$member" >"$extracted"
	local validation_plain
	validation_plain="$(new_temp_file)"; decrypt_file_to "$extracted" "$validation_plain"
	ensure_vault_parent
	acquire_vault_lock
	if [[ -e "$SAT_VAULT_FILE" && "$yes" == 'no' ]]; then release_vault_lock; fail 2 'confirmation_required' 'Vault sudah ada. Gunakan --yes setelah memastikan backup tersedia.'; fi
	if [[ -e "$SAT_VAULT_FILE" ]]; then
		existing_backup="$(mktemp "${SAT_VAULT_FILE}.pre-restore.$(date -u +%Y%m%dT%H%M%SZ).XXXXXX")"
		cp -- "$SAT_VAULT_FILE" "$existing_backup"
		chmod 600 -- "$existing_backup"
	fi
	restored_temp="$(mktemp "${SAT_VAULT_FILE}.restore.XXXXXX")"
	SAT_EXTERNAL_TEMP_FILES+=("$restored_temp")
	cp -- "$extracted" "$restored_temp"
	chmod 600 -- "$restored_temp"
	mv -f -- "$restored_temp" "$SAT_VAULT_FILE"
	release_vault_lock
	if [[ "$SAT_OUTPUT" == 'json' ]]; then jq -cn --arg path "$SAT_VAULT_FILE" --arg previous "$existing_backup" '{status:"restored",path:$path,previous_backup:$previous}'
	else printf 'Vault dipulihkan: %s\n' "$SAT_VAULT_FILE"; [[ -z "$existing_backup" ]] || printf 'Vault sebelumnya: %s\n' "$existing_backup"; fi
}

cmd_move() {
	set_json_output_if_requested "$@"
	local yes='no' name='' arg
	for arg in "$@"; do case "$arg" in --yes) yes='yes' ;; --json) ;; *) [[ -z "$name" ]] && name="$arg" ;; esac; done
	local backup_args=()
	[[ -z "$name" ]] || backup_args+=("$name")
	[[ "$SAT_OUTPUT" != 'json' ]] || backup_args+=('--json')
	SAT_BACKUP_SILENT='yes' cmd_backup "${backup_args[@]}"
	if [[ "$yes" == 'no' ]]; then
		[[ -t 0 ]] || fail 2 'confirmation_required' 'Gunakan --yes untuk menghapus vault setelah backup.'
		printf 'Ketik HAPUS VAULT untuk menghapus vault lokal: ' >&2
		local answer; IFS= read -r answer; [[ "$answer" == 'HAPUS VAULT' ]] || fail 2 'cancelled' 'Vault lokal tidak dihapus.'
	fi
	acquire_vault_lock
	[[ -f "$SAT_VAULT_FILE" ]] || { release_vault_lock; fail 4 'vault_missing' "$(t vault_missing)"; }
	local current_vault_sha256
	current_vault_sha256="$(sha256sum "$SAT_VAULT_FILE" | awk '{print $1}')"
	if [[ "$current_vault_sha256" != "$SAT_BACKUP_VAULT_SHA256" ]]; then
		release_vault_lock
		fail 8 'vault_changed' 'Vault berubah setelah backup dibuat; penghapusan dibatalkan.'
	fi
	if command -v shred >/dev/null 2>&1; then shred -u -- "$SAT_VAULT_FILE"; else rm -f -- "$SAT_VAULT_FILE"; fi
	release_vault_lock
	if [[ "$SAT_OUTPUT" == 'json' ]]; then
		jq -cn --arg path "$SAT_BACKUP_PATH" --arg sha256 "$SAT_BACKUP_SHA256" '{status:"moved",path:$path,sha256:$sha256,vault_deleted:true}'
	else
		printf 'Backup dibuat: %s\nSHA-256: %s\nVault lokal dihapus setelah backup terverifikasi.\n' "$SAT_BACKUP_PATH" "$SAT_BACKUP_SHA256"
	fi
}

web_running_pid() {
	local pid='' cmdline=''
	[[ -f "$SAT_WEB_PID_FILE" ]] || return 1
	IFS= read -r pid <"$SAT_WEB_PID_FILE" || true
	[[ "$pid" =~ ^[0-9]+$ ]] || { rm -f "$SAT_WEB_PID_FILE" "$SAT_WEB_STATE_FILE"; return 1; }
	[[ -r "/proc/$pid/cmdline" ]] || { rm -f "$SAT_WEB_PID_FILE" "$SAT_WEB_STATE_FILE"; return 1; }
	cmdline="$(tr '\0' ' ' <"/proc/$pid/cmdline")"
	[[ "$cmdline" == *"$SAT_ROOT/web/server.py"* ]] || { rm -f "$SAT_WEB_PID_FILE" "$SAT_WEB_STATE_FILE"; return 1; }
	kill -0 "$pid" 2>/dev/null || { rm -f "$SAT_WEB_PID_FILE" "$SAT_WEB_STATE_FILE"; return 1; }
	printf '%s' "$pid"
}

web_display_url() {
	local host="$1" port="$2"
	if [[ "$host" == *:* ]]; then printf 'http://[%s]:%s' "$host" "$port"; else printf 'http://%s:%s' "$host" "$port"; fi
}

resolve_web_display_host() {
	local bind_host="$1" detected=''
	if [[ -n "${SAT_WEB_DISPLAY_HOST:-}" ]]; then
		validate_host "$SAT_WEB_DISPLAY_HOST" || fail 6 'invalid_display_host' 'SAT_WEB_DISPLAY_HOST tidak valid.'
		printf '%s' "$SAT_WEB_DISPLAY_HOST"
		return
	fi
	case "$bind_host" in
		0.0.0.0|::)
			detected="$(hostname -I 2>/dev/null | awk '{print $1}')"
			if validate_host "$detected"; then printf '%s' "$detected"; else printf '127.0.0.1'; fi
			;;
		*) printf '%s' "$bind_host" ;;
	esac
}

web_health_check() {
	local host="$1" port="$2" check_host="$1"
	case "$check_host" in 0.0.0.0) check_host='127.0.0.1' ;; ::) check_host='::1' ;; esac
	python3 - "$check_host" "$port" <<'PY'
import http.client
import sys

connection = http.client.HTTPConnection(sys.argv[1], int(sys.argv[2]), timeout=0.8)
try:
	connection.request("GET", "/health")
	response = connection.getresponse()
	raise SystemExit(0 if response.status == 200 else 1)
except OSError:
	raise SystemExit(1)
finally:
	connection.close()
PY
}

parse_web_options() {
	local port_explicit='no' host_explicit='no'
	WEB_HOST="${SAT_WEB_HOST:-127.0.0.1}"; WEB_PORT="${SAT_WEB_PORT:-8787}"; WEB_TOKEN="$(read_web_token)"
	WEB_DOMAIN=''; WEB_CLOUDFLARE='off'; WEB_DEPLOYMENT='local'
	while (($#)); do
		case "$1" in
			--host) [[ $# -ge 2 ]] || fail 2 'usage' '--host membutuhkan nilai.'; WEB_HOST="$2"; host_explicit='yes'; shift 2 ;;
			--port) [[ $# -ge 2 ]] || fail 2 'usage' '--port membutuhkan nilai.'; WEB_PORT="$2"; port_explicit='yes'; shift 2 ;;
			--allow-network|--bind-any) WEB_HOST='0.0.0.0'; WEB_DEPLOYMENT='global'; shift ;;
			--domain) [[ $# -ge 2 ]] || fail 2 'usage' '--domain membutuhkan nilai.'; WEB_DOMAIN="${2,,}"; shift 2 ;;
			--cloudflare) [[ $# -ge 2 ]] || fail 2 'usage' '--cloudflare membutuhkan nilai.'; WEB_CLOUDFLARE="${2,,}"; shift 2 ;;
			--token) fail 2 'insecure_argument' 'Gunakan SAT_WEB_TOKEN_FD; token command-line tidak diterima.' ;;
			*) fail 2 'usage' "Argumen web tidak dikenal: $1" ;;
		esac
	done
	if [[ -n "$WEB_DOMAIN" ]]; then
		validate_domain_name "$WEB_DOMAIN" || fail 6 'invalid_domain' 'Domain/subdomain tidak valid. Gunakan hostname DNS seperti sat.example.com.'
		[[ "$host_explicit" == 'no' ]] || fail 2 'domain_host_conflict' 'Mode domain mengatur bind jaringan otomatis; jangan gabungkan --domain dan --host.'
		case "$WEB_CLOUDFLARE" in off|dns-only|proxied) ;; *) fail 6 'invalid_cloudflare_mode' 'Mode Cloudflare harus off, dns-only, atau proxied.' ;; esac
		WEB_HOST='0.0.0.0'; WEB_DEPLOYMENT='domain'
		if [[ "$WEB_CLOUDFLARE" == 'proxied' ]]; then
			[[ "$port_explicit" == 'yes' ]] || WEB_PORT='8080'
			is_cloudflare_http_port "$WEB_PORT" || fail 6 'cloudflare_port_unsupported' 'Proxy Cloudflare untuk origin HTTP hanya didukung SAT pada port 8080, 8880, 2052, 2082, 2086, atau 2095.'
		fi
	fi
	validate_host "$WEB_HOST" || fail 6 'invalid_host' 'Host hanya boleh berisi huruf, angka, titik, titik dua, persen, dan tanda hubung.'
	validate_port "$WEB_PORT" || fail 6 'invalid_port' 'Port harus 1024 sampai 65535.'
	if ! is_local_host "$WEB_HOST" && [[ -z "$WEB_TOKEN" ]]; then
		if [[ -t 0 ]]; then
			local token_confirmation=''
			printf 'Buat token akses Web UI (minimal 16 karakter): ' >&2
			IFS= read -r -s WEB_TOKEN
			printf '\nUlangi token akses: ' >&2
			IFS= read -r -s token_confirmation
			printf '\n' >&2
			[[ "$WEB_TOKEN" == "$token_confirmation" ]] || fail 6 'token_mismatch' 'Konfirmasi token Web UI tidak cocok.'
		else
			fail 6 'token_required' 'Binding jaringan membutuhkan token melalui prompt lokal atau SAT_WEB_TOKEN_FD.'
		fi
	fi
	if ! is_local_host "$WEB_HOST"; then validate_web_token "$WEB_TOKEN" || fail 6 'invalid_token' 'Token Web UI harus 16 sampai 256 karakter tanpa karakter kontrol.'; fi
}

run_web_server() {
	local mode="$1"; shift
	require_cmd python3
	parse_web_options "$@"; read_master_pass; validate_master_pass
	local server=(python3 "$SAT_ROOT/web/server.py" --host "$WEB_HOST" --port "$WEB_PORT" --script "$SAT_ROOT/sat.sh" --sat-home "$SAT_HOME" --version "$APP_VERSION" --password-fd 3 --token-fd 4)
	local web_url display_host
	if [[ -n "$WEB_DOMAIN" ]]; then display_host="$WEB_DOMAIN"; else display_host="$(resolve_web_display_host "$WEB_HOST")"; fi
	web_url="$(web_display_url "$display_host" "$WEB_PORT")"
	if [[ "$mode" == 'foreground' ]]; then
		printf 'SAT Web UI: %s\n' "$web_url"
		"${server[@]}" 3<<<"$SAT_MASTER_PASS_VALUE" 4<<<"$WEB_TOKEN"
	else
		ensure_sat_home
		local pid ready='no' attempt
		if pid="$(web_running_pid)"; then cmd_web_status; return; fi
		setsid "${server[@]}" 3<<<"$SAT_MASTER_PASS_VALUE" 4<<<"$WEB_TOKEN" >"$SAT_WEB_LOG_FILE" 2>&1 < /dev/null &
		pid=$!; printf '%s\n' "$pid" >"$SAT_WEB_PID_FILE"
		for attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
			if kill -0 "$pid" 2>/dev/null && web_health_check "$WEB_HOST" "$WEB_PORT"; then ready='yes'; break; fi
			sleep 0.2
		done
		if [[ "$ready" != 'yes' ]]; then
			kill -TERM "$pid" 2>/dev/null || true
			wait "$pid" 2>/dev/null || true
			rm -f "$SAT_WEB_PID_FILE" "$SAT_WEB_STATE_FILE"
			fail 8 'web_start_failed' "Web server tidak siap. Periksa konflik port dan $SAT_WEB_LOG_FILE"
		fi
		printf '%s\n%s\n%s\n%s\n%s\n' "$WEB_HOST" "$WEB_PORT" "$display_host" "$WEB_DEPLOYMENT" "$WEB_CLOUDFLARE" >"$SAT_WEB_STATE_FILE"
		chmod 600 -- "$SAT_WEB_PID_FILE" "$SAT_WEB_STATE_FILE" "$SAT_WEB_LOG_FILE"
		printf 'SAT Web UI berjalan (PID %s) di %s\n' "$pid" "$web_url"
		if [[ "$WEB_DEPLOYMENT" == 'domain' ]]; then
			printf 'Pointing DNS: buat record A/AAAA %s menuju IP publik VPS. Cloudflare: %s.\n' "$WEB_DOMAIN" "$WEB_CLOUDFLARE"
			printf 'Gunakan reverse proxy HTTPS tepercaya untuk akses permanen yang terenkripsi.\n'
		fi
	fi
}

cmd_web_stop() {
	local pid
	if ! pid="$(web_running_pid)"; then printf 'SAT Web UI tidak berjalan.\n'; return; fi
	kill -TERM "$pid"; local _; for _ in 1 2 3 4 5; do kill -0 "$pid" 2>/dev/null || break; sleep 0.2; done
	rm -f "$SAT_WEB_PID_FILE" "$SAT_WEB_STATE_FILE"; printf 'SAT Web UI dihentikan.\n'
}

cmd_web_status() {
	local pid host='' port='' display_host='' deployment='local' cloudflare='off' url=''
	if ! pid="$(web_running_pid)"; then
		printf 'SAT Web UI tidak berjalan. Jalankan: ./sat.sh web-start\n'
		return 1
	fi
	if [[ -f "$SAT_WEB_STATE_FILE" ]]; then
		{ IFS= read -r host; IFS= read -r port; IFS= read -r display_host || true; IFS= read -r deployment || true; IFS= read -r cloudflare || true; } <"$SAT_WEB_STATE_FILE" || true
		if validate_host "$host" && validate_port "$port"; then
			if ! validate_host "$display_host"; then display_host="$(resolve_web_display_host "$host")"; fi
			url="$(web_display_url "$display_host" "$port")"
		fi
	fi
	if [[ -n "$url" ]] && web_health_check "$host" "$port"; then
		printf 'SAT Web UI berjalan (PID %s). URL: %s Mode: %s' "$pid" "$url" "${deployment:-local}"
		[[ "$deployment" != 'domain' ]] || printf ' Cloudflare: %s' "${cloudflare:-off}"
		printf ' Log: %s\n' "$SAT_WEB_LOG_FILE"
	else
		printf 'SAT Web UI memiliki proses aktif tetapi endpoint belum sehat. Log: %s\n' "$SAT_WEB_LOG_FILE"
		return 1
	fi
}

interactive_website_menu() {
	while :; do
		local choice domain uses_cloudflare proxy_mode cloudflare_mode
		if [[ "$SAT_LANG" == 'en' ]]; then
			printf '\nWebsite\n1 Global VPS / IP\n2 Domain / subdomain\n3 Status\n4 Stop\n0 Back\nChoice: '
		else
			printf '\nWebsite\n1 Global VPS / IP\n2 Domain / subdomain\n3 Status\n4 Stop\n0 Kembali\nPilihan: '
		fi
		IFS= read -r choice
		case "$choice" in
			1) run_web_server background --allow-network ;;
			2)
				if [[ "$SAT_LANG" == 'en' ]]; then printf 'Domain/subdomain: '; else printf 'Domain/subdomain: '; fi
				IFS= read -r domain
				if [[ "$SAT_LANG" == 'en' ]]; then printf 'Is DNS managed by Cloudflare? [y/N]: '; else printf 'Apakah DNS menggunakan Cloudflare? [y/N]: '; fi
				IFS= read -r uses_cloudflare
				cloudflare_mode='off'
				case "${uses_cloudflare,,}" in
					y|yes|ya)
						if [[ "$SAT_LANG" == 'en' ]]; then printf 'Is the DNS record proxied (orange cloud)? [y/N]: '; else printf 'Apakah record memakai proxy (orange cloud)? [y/N]: '; fi
						IFS= read -r proxy_mode
						case "${proxy_mode,,}" in y|yes|ya) cloudflare_mode='proxied' ;; *) cloudflare_mode='dns-only' ;; esac
						;;
				esac
				run_web_server background --domain "$domain" --cloudflare "$cloudflare_mode"
				;;
			3) cmd_web_status || true ;;
			4) cmd_web_stop ;;
			0) return ;;
			*) if [[ "$SAT_LANG" == 'en' ]]; then printf 'Unknown choice.\n'; else printf 'Pilihan tidak dikenal.\n'; fi ;;
		esac
	done
}

interactive_menu() {
	print_banner
	while :; do
		local choice label query
		if [[ "$SAT_LANG" == 'en' ]]; then
			printf '\nSAT %s\n1) List OTP entries\n2) Add OTP entry\n3) Generate OTP code\n4) Search OTP entries\n5) Website\n6) Backup\n0) Exit\nChoice: ' "$APP_VERSION"
		else
			printf '\nSAT %s\n1) Daftar entri OTP\n2) Tambah OTP\n3) Hasilkan kode OTP\n4) Cari entri OTP\n5) Website\n6) Backup\n0) Keluar\nPilihan: ' "$APP_VERSION"
		fi
		IFS= read -r choice
		case "$choice" in
			1) cmd_list ;;
			2) cmd_add ;;
			3) printf 'Label: '; IFS= read -r label; cmd_code "$label" ;;
			4) printf 'Query: '; IFS= read -r query; cmd_search "$query" ;;
			5) interactive_website_menu ;;
			6) cmd_backup ;;
			0) return ;;
			*) printf 'Pilihan tidak dikenal.\n' ;;
		esac
	done
}

main() {
	local command="${1:-menu}"
	[[ $# -eq 0 ]] || shift
	case "$command" in
		help|-h|--help) cmd_help ;;
		version|--version|-V) set_json_output_if_requested "$@"; cmd_version ;;
		doctor) set_json_output_if_requested "$@"; cmd_doctor ;;
		init) require_cmd jq; set_json_output_if_requested "$@"; cmd_init ;;
		add) require_cmd jq; cmd_add "$@" ;;
		update|edit) require_cmd jq; cmd_update "$@" ;;
		list) require_cmd jq; cmd_list "$@" ;;
		search|find) require_cmd jq; cmd_search "$@" ;;
		show) require_cmd jq; cmd_show "$@" ;;
		code) require_cmd jq; cmd_code "$@" ;;
		codes) require_cmd jq; cmd_codes "$@" ;;
		delete|del|rm) require_cmd jq; cmd_delete "$@" ;;
		backup|export|portable) require_cmd jq; cmd_backup "$@" ;;
		restore) require_cmd jq; cmd_restore "$@" ;;
		move) require_cmd jq; cmd_move "$@" ;;
		web) require_cmd jq; run_web_server foreground "$@" ;;
		web-start) require_cmd jq; run_web_server background "$@" ;;
		web-public) require_cmd jq; run_web_server background --allow-network "$@" ;;
		web-domain)
			require_cmd jq
			[[ $# -ge 1 ]] || fail 2 'usage' 'Gunakan: sat.sh web-domain <domain> [--cloudflare off|dns-only|proxied] [--port PORT]'
			local web_domain="$1"; shift
			run_web_server background --domain "$web_domain" "$@"
			;;
		web-stop) require_cmd jq; cmd_web_stop ;;
		web-status) require_cmd jq; cmd_web_status ;;
		menu) require_cmd jq; interactive_menu ;;
		*) fail 2 'unknown_command' "Command tidak dikenal: $command" ;;
	esac
}
