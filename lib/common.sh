#!/usr/bin/env bash

# shellcheck disable=SC2034 # consumed by modules sourced by sat.sh
APP_NAME='SAT - Silent Authenticator Tool'
APP_VERSION="$(tr -d '\r\n' <"$SAT_ROOT/VERSION")"
[[ "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { printf 'Invalid SAT version in %s/VERSION\n' "$SAT_ROOT" >&2; exit 70; }
# shellcheck disable=SC2034 # consumed by the interactive UI module
SAT_LANG_EXPLICIT='no'
[[ -n "${SAT_LANG+x}" ]] && SAT_LANG_EXPLICIT='yes'
SAT_LANG="${SAT_LANG:-id}"
SAT_OUTPUT="${SAT_OUTPUT:-text}"
SAT_HOME="${SAT_HOME:-${HOME}/.sat}"
SAT_VAULT_FILE="${SAT_VAULT_FILE:-$SAT_HOME/otp.vault}"
SAT_LOCK_FILE="${SAT_LOCK_FILE:-${SAT_VAULT_FILE}.lock}"
SAT_WEB_PID_FILE="${SAT_WEB_PID_FILE:-$SAT_HOME/sat-web.pid}"
SAT_WEB_LOG_FILE="${SAT_WEB_LOG_FILE:-$SAT_HOME/sat-web.log}"
SAT_WEB_STATE_FILE="${SAT_WEB_STATE_FILE:-$SAT_HOME/sat-web.state}"
SAT_WEB_CLOUDFLARE_CREDENTIALS="${SAT_WEB_CLOUDFLARE_CREDENTIALS:-$SAT_HOME/cloudflare.ini}"
SAT_WEB_RESTART_KEY_FILE="${SAT_WEB_RESTART_KEY_FILE:-$SAT_HOME/sat-web-restart.key}"
SAT_WEB_RESTART_CREDENTIALS_FILE="${SAT_WEB_RESTART_CREDENTIALS_FILE:-$SAT_HOME/sat-web-restart.enc}"
SAT_CONFIG_FILE="${SAT_CONFIG_FILE:-$SAT_HOME/config}"
SAT_MASTER_PASS_VALUE=''
SAT_EXTERNAL_TEMP_FILES=()

case "${SAT_LANG,,}" in
	id|en) SAT_LANG="${SAT_LANG,,}" ;;
	*) SAT_LANG='id' ;;
esac

case "$SAT_OUTPUT" in
	text|json) ;;
	*) SAT_OUTPUT='text' ;;
esac

umask 077

SAT_PROCESS_TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/sat.$$.XXXXXX")"
chmod 700 -- "$SAT_PROCESS_TEMP_DIR"

cleanup_sat_temp_files() {
	local path
	for path in "${SAT_EXTERNAL_TEMP_FILES[@]-}"; do
		if [[ -n "$path" ]]; then rm -f -- "$path" 2>/dev/null || true; fi
	done
	if [[ -n "${SAT_PROCESS_TEMP_DIR:-}" && -d "$SAT_PROCESS_TEMP_DIR" ]]; then
		rm -rf -- "$SAT_PROCESS_TEMP_DIR" 2>/dev/null || true
	fi
}

trap cleanup_sat_temp_files EXIT

t() {
	local id="$1"
	if [[ "$SAT_LANG" == 'en' ]]; then
		case "$id" in
			dependency_missing) printf 'Required dependency is missing: %s' "$2" ;;
			vault_missing) printf 'Vault not found. Run sat.sh init first.' ;;
			wrong_password) printf 'Could not unlock the vault. Check the password or vault integrity.' ;;
			invalid_input) printf 'Invalid input: %s' "$2" ;;
			*) printf '%s' "$id" ;;
		esac
	else
		case "$id" in
			dependency_missing) printf 'Dependensi wajib tidak ditemukan: %s' "$2" ;;
			vault_missing) printf 'Vault tidak ditemukan. Jalankan sat.sh init terlebih dahulu.' ;;
			wrong_password) printf 'Vault tidak dapat dibuka. Periksa password atau integritas vault.' ;;
			invalid_input) printf 'Input tidak valid: %s' "$2" ;;
			*) printf '%s' "$id" ;;
		esac
	fi
}

json_error() {
	local code="$1" message="$2"
	if command -v jq >/dev/null 2>&1; then
		jq -cn --arg error "$code" --arg message "$message" '{error:$error,message:$message}'
	else
		printf '{"error":"dependency_missing","message":"jq is required for JSON error output"}\n'
	fi
}

fail() {
	local exit_code="$1" error_code="$2" message="$3"
	if [[ "$SAT_OUTPUT" == 'json' ]]; then
		json_error "$error_code" "$message" >&2
	else
		if declare -F ui_localize_message >/dev/null 2>&1; then message="$(ui_localize_message "$message")"; fi
		printf 'Error: %s\n' "$message" >&2
	fi
	exit "$exit_code"
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || fail 7 'dependency_missing' "$(t dependency_missing "$1")"
}

ensure_sat_home() {
	mkdir -p -- "$SAT_HOME"
	chmod 700 -- "$SAT_HOME"
}

new_temp_file() {
	local path
	path="$(mktemp "$SAT_PROCESS_TEMP_DIR/file.XXXXXX")"
	chmod 600 -- "$path"
	printf '%s' "$path"
}

new_temp_dir() {
	local path
	path="$(mktemp -d "$SAT_PROCESS_TEMP_DIR/dir.XXXXXX")"
	chmod 700 -- "$path"
	printf '%s' "$path"
}

read_secret_from_fd() {
	local fd="$1" value=''
	[[ "$fd" =~ ^[0-9]+$ ]] || return 1
	IFS= read -r -u "$fd" value || true
	printf '%s' "$value"
}

read_master_pass() {
	[[ -n "$SAT_MASTER_PASS_VALUE" ]] && return
	if [[ -n "${SAT_MASTER_PASS_FD:-}" ]]; then
		SAT_MASTER_PASS_VALUE="$(read_secret_from_fd "$SAT_MASTER_PASS_FD")"
	else
		[[ -t 0 ]] || fail 3 'password_required' 'Master password harus diberikan melalui terminal atau SAT_MASTER_PASS_FD.'
		if declare -F ui >/dev/null 2>&1; then ui master_password >&2; else printf 'Master password: ' >&2; fi
		IFS= read -r -s SAT_MASTER_PASS_VALUE
		printf '\n' >&2
	fi
	[[ -n "$SAT_MASTER_PASS_VALUE" ]] || fail 3 'password_required' 'Master password tidak boleh kosong.'
}

read_web_token() {
	local token=''
	if [[ -n "${SAT_WEB_TOKEN_FD:-}" ]]; then
		token="$(read_secret_from_fd "$SAT_WEB_TOKEN_FD")"
	fi
	printf '%s' "$token"
}

validate_label() {
	local label="$1"
	[[ -n "$label" && ${#label} -le 128 ]] || return 1
	[[ "$label" != *$'\n'* && "$label" != *$'\r'* && "$label" != *$'\t'* ]] || return 1
	[[ "$label" =~ ^[[:print:]]+$ ]]
}

validate_text() {
	local value="$1" max_length="$2"
	[[ ${#value} -le max_length ]] || return 1
	[[ "$value" != *$'\n'* && "$value" != *$'\r'* && "$value" != *$'\t'* ]]
}

normalize_secret() {
	printf '%s' "$1" | tr -d '[:space:]-' | tr '[:lower:]' '[:upper:]'
}

validate_secret() {
	[[ ${#1} -le 1024 && "$1" =~ ^[A-Z2-7]{8,}={0,6}$ ]]
}

validate_digits() {
	[[ "$1" =~ ^(6|7|8|9|10)$ ]]
}

validate_period() {
	[[ "$1" =~ ^[0-9]+$ ]] && ((10#$1 >= 15 && 10#$1 <= 90))
}

validate_algo() {
	[[ "$1" =~ ^(SHA1|SHA256|SHA512)$ ]]
}

validate_port() {
	[[ "$1" =~ ^[0-9]+$ ]] && ((10#$1 >= 1024 && 10#$1 <= 65535))
}

validate_host() {
	[[ -n "$1" && ${#1} -le 253 && "$1" =~ ^[A-Za-z0-9:.%-]+$ ]]
}

validate_domain_name() {
	local domain="${1,,}" label
	[[ -n "$domain" && ${#domain} -le 253 ]] || return 1
	[[ "$domain" != .* && "$domain" != *. && "$domain" == *.* ]] || return 1
	IFS='.' read -r -a labels <<<"$domain"
	for label in "${labels[@]}"; do
		[[ -n "$label" && ${#label} -le 63 ]] || return 1
		[[ "$label" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || return 1
	done
}

is_cloudflare_http_port() {
	case "$1" in
		8080|8880|2052|2082|2086|2095) return 0 ;;
		*) return 1 ;;
	esac
}

validate_web_token() {
	[[ ${#1} -ge 16 && ${#1} -le 256 ]]
	[[ "$1" != *$'\n'* && "$1" != *$'\r'* && "$1" != *$'\t'* ]]
}

is_local_host() {
	case "$1" in
		127.0.0.1|localhost|::1) return 0 ;;
		*) return 1 ;;
	esac
}
