#!/usr/bin/env bash

# Human-facing terminal UI. Keep machine-readable commands independent from this
# module: JSON output and explicit SAT_LANG callers must remain non-interactive.

ui_is_english() {
	[[ "$SAT_LANG" == 'en' ]]
}

ui() {
	local key="$1"
	if ui_is_english; then
		case "$key" in
			language_choice) printf 'Choose your language / Pilih bahasa\n\n  1) English\n  2) Bahasa Indonesia\n\nSelect / Pilih [1-2]: ' ;;
			language_saved) printf 'Language preference saved.' ;;
			invalid_choice) printf 'Please choose a listed option.' ;;
			main_menu) printf '1) List OTP entries\n2) Add OTP entry\n3) Generate OTP code\n4) Search OTP entries\n5) Website\n6) Backup\n7) Language\n0) Exit' ;;
			website_menu) printf '1) Global VPS / IP\n2) Domain / subdomain with HTTPS\n3) Status\n4) Stop\n0) Back' ;;
			choice) printf 'Choice: ' ;;
			website) printf 'Website' ;;
			web_address) printf 'Web UI Address' ;;
			domain_prompt) printf 'Domain or subdomain: ' ;;
			port_prompt) printf 'Port [%s]: ' "$2" ;;
			invalid_domain) printf 'Enter a valid DNS hostname, for example sat.example.com.' ;;
			invalid_port) printf 'Port must be between 1024 and 65535.' ;;
			dns_configuration) printf 'DNS Configuration' ;;
			cloudflare_use) printf 'Does this domain use Cloudflare? [Y/n]: ' ;;
			cloudflare_proxy) printf 'Use Cloudflare proxy (orange cloud)? [y/N]: ' ;;
			domain_requires_cloudflare) printf 'HTTPS domain setup currently uses Cloudflare DNS TXT validation. Choose a Cloudflare-managed domain or return to the Website menu.' ;;
			web_security) printf 'Web UI Security' ;;
			web_token) printf 'Web UI access token (minimum 16 characters): ' ;;
			web_token_confirm) printf 'Confirm Web UI access token: ' ;;
			web_token_invalid) printf 'Token must contain 16 to 256 characters and no control characters.' ;;
			web_token_mismatch) printf 'Web UI access token confirmation does not match.' ;;
			master_password) printf 'Master password: ' ;;
			label) printf 'Label: ' ;;
			issuer) printf 'Issuer: ' ;;
			account) printf 'Account: ' ;;
			secret_base32) printf 'BASE32 secret: ' ;;
			query) printf 'Query: ' ;;
			cloudflare) printf 'Cloudflare' ;;
			cloudflare_stored) printf 'Stored Cloudflare credentials were found.' ;;
			cloudflare_reuse) printf 'Use the stored Cloudflare token? [Y/n]: ' ;;
			cloudflare_token_info) printf 'A restricted Cloudflare API token is required to create the DNS TXT validation record.\nGrant Zone > Zone > Read and Zone > DNS > Edit for this zone only.' ;;
			cloudflare_token) printf 'Cloudflare API token (hidden): ' ;;
			cloudflare_token_required) printf 'A Cloudflare API token is required for DNS TXT validation.' ;;
			cloudflare_saved) printf 'Cloudflare credentials saved securely for certificate renewal.' ;;
			security_notice) printf 'Security Notice' ;;
			cloudflare_trust) printf 'Cloudflare terminates TLS at its edge when proxying is enabled.\nThis makes Cloudflare part of the Web UI trust boundary.' ;;
			cloudflare_accept) printf 'Accept this configuration? Type "yes" to continue: ' ;;
			tls_certificate) printf 'TLS Certificate' ;;
			letsencrypt_email) printf "Let's Encrypt contact email (optional): " ;;
			configuration_summary) printf 'Configuration Summary' ;;
			apply_configuration) printf 'Apply this configuration? [Y/n]: ' ;;
			cancelled) printf 'Configuration cancelled. No system changes were made.' ;;
			stage_tls) printf '[1/2] Requesting and validating the TLS certificate...' ;;
			stage_nginx) printf '[2/2] Configuring Nginx HTTPS reverse proxy...' ;;
			setup_success) printf 'SAT Web UI configured successfully' ;;
			url) printf 'URL' ;;
			upstream) printf 'Upstream' ;;
			https) printf 'HTTPS' ;;
			active) printf 'Active' ;;
			enabled) printf 'Enabled' ;;
			disabled) printf 'Disabled' ;;
			proxy) printf 'Proxy' ;;
			cloudflare_label) printf 'Cloudflare' ;;
			language) printf 'Language' ;;
			cloudflare_strict) printf 'Set Cloudflare SSL/TLS mode to Full (strict).' ;;
			localhost_only) printf 'SAT listens only on localhost. Nginx handles HTTPS and reverse proxying.' ;;
			unknown_choice) printf 'Unknown choice.' ;;
			back_or_cancel) printf 'Type cancel to return: ' ;;
			*) printf '%s' "$key" ;;
		esac
	else
		case "$key" in
			language_choice) printf 'Choose your language / Pilih bahasa\n\n  1) English\n  2) Bahasa Indonesia\n\nSelect / Pilih [1-2]: ' ;;
			language_saved) printf 'Preferensi bahasa disimpan.' ;;
			invalid_choice) printf 'Pilih opsi yang tersedia.' ;;
			main_menu) printf '1) Daftar entri OTP\n2) Tambah OTP\n3) Hasilkan kode OTP\n4) Cari entri OTP\n5) Website\n6) Backup\n7) Bahasa\n0) Keluar' ;;
			website_menu) printf '1) Global VPS / IP\n2) Domain / subdomain dengan HTTPS\n3) Status\n4) Stop\n0) Kembali' ;;
			choice) printf 'Pilihan: ' ;;
			website) printf 'Website' ;;
			web_address) printf 'Alamat Web UI' ;;
			domain_prompt) printf 'Domain atau subdomain: ' ;;
			port_prompt) printf 'Port [%s]: ' "$2" ;;
			invalid_domain) printf 'Masukkan hostname DNS yang valid, misalnya sat.example.com.' ;;
			invalid_port) printf 'Port harus antara 1024 dan 65535.' ;;
			dns_configuration) printf 'Konfigurasi DNS' ;;
			cloudflare_use) printf 'Apakah domain ini menggunakan Cloudflare? [Y/n]: ' ;;
			cloudflare_proxy) printf 'Gunakan proxy Cloudflare (orange cloud)? [y/N]: ' ;;
			domain_requires_cloudflare) printf 'Setup HTTPS domain saat ini menggunakan validasi TXT DNS Cloudflare. Pilih domain yang dikelola Cloudflare atau kembali ke menu Website.' ;;
			web_security) printf 'Keamanan Web UI' ;;
			web_token) printf 'Token akses Web UI (minimal 16 karakter): ' ;;
			web_token_confirm) printf 'Ulangi token akses Web UI: ' ;;
			web_token_invalid) printf 'Token harus 16 sampai 256 karakter dan tidak boleh mengandung karakter kontrol.' ;;
			web_token_mismatch) printf 'Konfirmasi token akses Web UI tidak cocok.' ;;
			master_password) printf 'Master password: ' ;;
			label) printf 'Label: ' ;;
			issuer) printf 'Issuer: ' ;;
			account) printf 'Account: ' ;;
			secret_base32) printf 'Secret BASE32: ' ;;
			query) printf 'Kueri: ' ;;
			cloudflare) printf 'Cloudflare' ;;
			cloudflare_stored) printf 'Kredensial Cloudflare tersimpan ditemukan.' ;;
			cloudflare_reuse) printf 'Gunakan token Cloudflare yang tersimpan? [Y/n]: ' ;;
			cloudflare_token_info) printf 'Token API Cloudflare terbatas diperlukan untuk membuat record TXT validasi DNS.\nBerikan Zone > Zone > Read dan Zone > DNS > Edit hanya untuk zone ini.' ;;
			cloudflare_token) printf 'Token API Cloudflare (tersembunyi): ' ;;
			cloudflare_token_required) printf 'Token API Cloudflare diperlukan untuk validasi TXT DNS.' ;;
			cloudflare_saved) printf 'Kredensial Cloudflare disimpan dengan aman untuk pembaruan sertifikat.' ;;
			security_notice) printf 'Pemberitahuan Keamanan' ;;
			cloudflare_trust) printf 'Saat proxy diaktifkan, Cloudflare melakukan terminasi TLS di edge.\nArtinya Cloudflare menjadi bagian dari trust boundary Web UI.' ;;
			cloudflare_accept) printf 'Terima konfigurasi ini? Ketik "yes" untuk melanjutkan: ' ;;
			tls_certificate) printf 'Sertifikat TLS' ;;
			letsencrypt_email) printf "Email kontak Let's Encrypt (opsional): " ;;
			configuration_summary) printf 'Ringkasan Konfigurasi' ;;
			apply_configuration) printf 'Terapkan konfigurasi ini? [Y/n]: ' ;;
			cancelled) printf 'Konfigurasi dibatalkan. Tidak ada perubahan sistem yang dibuat.' ;;
			stage_tls) printf '[1/2] Memvalidasi DNS dan menyiapkan sertifikat TLS...' ;;
			stage_nginx) printf '[2/2] Mengonfigurasi reverse proxy HTTPS Nginx...' ;;
			setup_success) printf 'SAT Web UI berhasil dikonfigurasi' ;;
			url) printf 'URL' ;;
			upstream) printf 'Upstream' ;;
			https) printf 'HTTPS' ;;
			active) printf 'Aktif' ;;
			enabled) printf 'Aktif' ;;
			disabled) printf 'Nonaktif' ;;
			proxy) printf 'Proxy' ;;
			cloudflare_label) printf 'Cloudflare' ;;
			language) printf 'Bahasa' ;;
			cloudflare_strict) printf 'Setel mode SSL/TLS Cloudflare ke Full (strict).' ;;
			localhost_only) printf 'SAT hanya mendengarkan di localhost. Nginx menangani HTTPS dan reverse proxy.' ;;
			unknown_choice) printf 'Pilihan tidak dikenal.' ;;
			back_or_cancel) printf 'Ketik cancel untuk kembali: ' ;;
			*) printf '%s' "$key" ;;
		esac
	fi
}

ui_section() {
	printf '\n%s\n%s\n' '────────────────────────────────────────' "$(ui "$1")"
}

ui_parse_boolean() {
	case "${1,,}" in
		y|yes|ya) printf yes ;;
		n|no|tidak) printf no ;;
		'') printf default ;;
		*) return 1 ;;
	esac
}

ui_confirm() {
	local prompt="$1" default="$2" answer parsed
	while :; do
		ui "$prompt"
		IFS= read -r answer || return 1
		parsed="$(ui_parse_boolean "$answer")" || { printf '%s\n' "$(ui invalid_choice)" >&2; continue; }
		[[ "$parsed" == default ]] && parsed="$default"
		printf '%s' "$parsed"
		return 0
	done
}

load_saved_language() {
	local key value saved=''
	[[ "$SAT_LANG_EXPLICIT" == 'no' && -r "$SAT_CONFIG_FILE" && ! -L "$SAT_CONFIG_FILE" ]] || return 0
	while IFS='=' read -r key value; do
		[[ "$key" == 'language' ]] && saved="$value"
	done <"$SAT_CONFIG_FILE"
	case "${saved,,}" in
		id|en) SAT_LANG="${saved,,}" ;;
		'') ;;
		*) SAT_LANG='en' ;;
	esac
	return 0
}

save_language() {
	local temporary
	ensure_sat_home
	temporary="$(mktemp "$SAT_HOME/.config.XXXXXX")"
	chmod 600 -- "$temporary"
	printf 'language=%s\n' "$SAT_LANG" >"$temporary"
	mv -f -- "$temporary" "$SAT_CONFIG_FILE"
	chmod 600 -- "$SAT_CONFIG_FILE"
}

select_terminal_language() {
	local force="${1:-no}" choice
	[[ "$force" == yes || "$SAT_LANG_EXPLICIT" == no ]] || return 0
	[[ -t 0 && -t 1 ]] || { load_saved_language; return; }
	load_saved_language
	if [[ "$force" != yes && -f "$SAT_CONFIG_FILE" ]]; then return; fi
	while :; do
		printf '\n'; ui language_choice
		IFS= read -r choice || return 1
		case "$choice" in
			1|en|EN) SAT_LANG='en' ;;
			2|id|ID) SAT_LANG='id' ;;
			*) printf '%s\n' "$(ui invalid_choice)" >&2; continue ;;
		esac
		save_language
		printf '%s\n' "$(ui language_saved)"
		return
	done
}
