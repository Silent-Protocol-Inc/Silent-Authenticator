#!/usr/bin/env bash

acquire_vault_lock() {
	ensure_sat_home
	require_cmd flock
	exec {SAT_VAULT_LOCK_FD}>"$SAT_LOCK_FILE"
	flock -w 10 "$SAT_VAULT_LOCK_FD" || fail 8 'vault_busy' 'Vault sedang dipakai proses lain.'
}

release_vault_lock() {
	if [[ -n "${SAT_VAULT_LOCK_FD:-}" ]]; then
		flock -u "$SAT_VAULT_LOCK_FD" 2>/dev/null || true
		exec {SAT_VAULT_LOCK_FD}>&-
		unset SAT_VAULT_LOCK_FD
	fi
}

ensure_vault_parent() {
	local vault_parent
	vault_parent="$(dirname -- "$SAT_VAULT_FILE")"
	if [[ ! -e "$vault_parent" ]]; then
		mkdir -p -- "$vault_parent"
		chmod 700 -- "$vault_parent"
	fi
	[[ -d "$vault_parent" && -w "$vault_parent" ]] || fail 8 'vault_path_unwritable' "Direktori vault tidak dapat ditulis: $vault_parent"
}

decrypt_file_to() {
	local encrypted_input="$1" output_file="$2"
	require_cmd openssl
	require_cmd jq
	[[ -f "$encrypted_input" ]] || fail 4 'vault_missing' "$(t vault_missing)"
	read_master_pass
	if ! printf '%s' "$SAT_MASTER_PASS_VALUE" | openssl enc -aes-256-cbc -pbkdf2 -d -salt \
		-in "$encrypted_input" -out "$output_file" -pass stdin 2>/dev/null; then
		fail 3 'unlock_failed' "$(t wrong_password)"
	fi
	jq -e 'type == "object"' "$output_file" >/dev/null 2>&1 || fail 3 'vault_corrupt' 'Isi vault tidak valid.'
}

decrypt_vault_to() {
	local output_file="$1"
	decrypt_file_to "$SAT_VAULT_FILE" "$output_file"
}

encrypt_file_to_vault() {
	local input_file="$1" encrypted_file
	require_cmd openssl
	read_master_pass
	ensure_vault_parent
	encrypted_file="$(mktemp "${SAT_VAULT_FILE}.new.XXXXXX")"
	chmod 600 -- "$encrypted_file"
	SAT_EXTERNAL_TEMP_FILES+=("$encrypted_file")
	if ! printf '%s' "$SAT_MASTER_PASS_VALUE" | openssl enc -aes-256-cbc -pbkdf2 -salt \
		-in "$input_file" -out "$encrypted_file" -pass stdin 2>/dev/null; then
		fail 3 'encrypt_failed' 'Vault gagal dienkripsi.'
	fi
	mv -f -- "$encrypted_file" "$SAT_VAULT_FILE"
}

validate_master_pass() {
	local plain
	plain="$(new_temp_file)"
	decrypt_vault_to "$plain"
}

read_vault() {
	local output_file="$1"
	acquire_vault_lock
	decrypt_vault_to "$output_file"
	release_vault_lock
}

mutate_vault_with_jq() {
	local filter="$1"
	shift
	local plain updated
	plain="$(new_temp_file)"
	updated="$(new_temp_file)"
	acquire_vault_lock
	decrypt_vault_to "$plain"
	jq "$@" "$filter" "$plain" >"$updated"
	encrypt_file_to_vault "$updated"
	release_vault_lock
}
