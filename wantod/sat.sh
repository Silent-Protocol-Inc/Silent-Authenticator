#!/usr/bin/env bash
# SAT - Silent Authenticator Tool
# Simple TOTP manager (terminal) dengan vault terenkripsi.

set -euo pipefail

APP_NAME="SAT - Silent Authenticator Tool"
APP_VERSION="1.0.0"
SAT_OUTPUT="${SAT_OUTPUT:-text}" # text | json (untuk API/web)
SAT_WEB_TOKEN="${SAT_WEB_TOKEN:-}" # optional shared secret untuk web API
SAT_LANG="${SAT_LANG:-id}" # id | en

case "${SAT_LANG,,}" in
	id|en) SAT_LANG="${SAT_LANG,,}" ;;
	*) SAT_LANG="id" ;;
esac
SAT_LANG="${SAT_LANG:-id}" # id | en

VAULT_DIR="${HOME}/.sat"
VAULT_FILE="${VAULT_DIR}/otp.vault"
WEB_PID_FILE="${VAULT_DIR}/sat-web.pid"
WEB_LOG_FILE="${VAULT_DIR}/sat-web.log"

umask 077
TMP_FILE="$(mktemp -t sat_otp.XXXXXX)"
trap 'rm -f "$TMP_FILE" 2>/dev/null || true' EXIT

# -------------------------------------------------------------------
# Banner & Status
# -------------------------------------------------------------------

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

Silent Authenticator Tool (SAT)  v1.0.0  © 2025 SilentProtocol. All rights reserved.

EOF
}

print_status() {
	echo "Version   : ${APP_VERSION}"
	echo "Vault dir : ${VAULT_DIR}"
	echo "Vault path: ${VAULT_FILE}"
	echo "Language  : ${SAT_LANG}"
	if [[ -f "$VAULT_FILE" ]]; then
		echo "Vault exist: yes"
	else
		echo "Vault exist: no (run INIT first)"
	fi
	echo
}

# -------------------------------------------------------------------
# Util
# -------------------------------------------------------------------

die() {
	echo "❌ $*" >&2
	exit 1
}

require_cmd() {
	command -v "$1" >/dev/null 2>&1 || die "Dependensi '$1' tidak ditemukan. Install dulu."
}

# Simple bilingual text helper (CLI menu)
t_cli() {
	local key="$1"
	case "$SAT_LANG" in
		en)
			case "$key" in
				menu_1) echo "List OTP entries" ;;
				menu_2) echo "Add OTP entry" ;;
				menu_3) echo "Show OTP detail" ;;
				menu_4) echo "Generate OTP (single)" ;;
				menu_5) echo "Generate OTP (live)" ;;
				menu_6) echo "Delete OTP entry" ;;
				menu_7) echo "Launch Web UI (live codes)" ;;
				menu_8) echo "Create portable bundle (SAVE + wipe vault)" ;;
				menu_9) echo "Help / usage" ;;
				menu_10) echo "Change language (id/en)" ;;
				menu_0) echo "Exit" ;;
				prompt_choice) echo "Choose an option: " ;;
				prompt_label_example) echo "Label (e.g., discord-main): " ;;
				prompt_label_view) echo "Label to view: " ;;
				prompt_label_code) echo "Label OTP: " ;;
				prompt_label_live) echo "Label OTP (live mode): " ;;
				prompt_label_delete) echo "Label to delete: " ;;
				warn_label_empty) echo "⚠️ Label cannot be empty." ;;
				web_info_1) echo "Web UI shows OTP list and live codes (auto-refresh)." ;;
				web_info_2) echo "Use host 0.0.0.0 or VPS IP + token for public access." ;;
				web_prompt_host) echo "Host [default %s]: " ;;
				web_prompt_port) echo "Port [8787]: " ;;
				web_prompt_token) echo "Token (recommended if public, leave empty if not needed): " ;;
				bundle_prompt_name) echo "Bundle name (leave empty for auto): " ;;
				lang_prompt) echo "Choose language [id/en] (current: %s): " ;;
				lang_set) echo "Language set to: %s" ;;
				lang_keep) echo "Kept language: %s" ;;
				lang_invalid) echo "⚠️ Unknown input. Choose 'id' or 'en'." ;;
				choice_invalid) echo "⚠️ Unknown choice: %s" ;;
				press_enter) echo "Press Enter to return to menu..." ;;
				bye) echo "Bye." ;;
				*) echo "$key" ;;
			esac
			;;
		*)
			case "$key" in
				menu_1) echo "Daftar entri OTP" ;;
				menu_2) echo "Tambah OTP" ;;
				menu_3) echo "Lihat detail OTP" ;;
				menu_4) echo "Hasilkan OTP (sekali)" ;;
				menu_5) echo "Hasilkan OTP (live)" ;;
				menu_6) echo "Hapus OTP" ;;
				menu_7) echo "Jalankan Web UI (kode live)" ;;
				menu_8) echo "Buat bundle portable (simpan + hapus vault)" ;;
				menu_9) echo "Panduan / penggunaan" ;;
				menu_10) echo "Ganti bahasa (id/en)" ;;
				menu_0) echo "Keluar" ;;
				prompt_choice) echo "Pilih opsi: " ;;
				prompt_label_example) echo "Label (contoh: discord-main): " ;;
				prompt_label_view) echo "Label yang mau dilihat: " ;;
				prompt_label_code) echo "Label OTP: " ;;
				prompt_label_live) echo "Label OTP (mode live): " ;;
				prompt_label_delete) echo "Label yang mau dihapus: " ;;
				warn_label_empty) echo "⚠️ Label tidak boleh kosong." ;;
				web_info_1) echo "Web UI menampilkan daftar OTP + kode live (refresh otomatis)." ;;
				web_info_2) echo "Untuk VPS/public IP gunakan host 0.0.0.0 atau IP VPS + token." ;;
				web_prompt_host) echo "Host [%s]: " ;;
				web_prompt_port) echo "Port [8787]: " ;;
				web_prompt_token) echo "Token (disarankan jika publik, kosongkan jika tidak perlu): " ;;
				bundle_prompt_name) echo "Nama bundle (kosongkan untuk auto): " ;;
				lang_prompt) echo "Pilih bahasa [id/en] (saat ini: %s): " ;;
				lang_set) echo "Bahasa diatur ke: %s" ;;
				lang_keep) echo "Bahasa tetap: %s" ;;
				lang_invalid) echo "⚠️ Input tidak dikenal. Pilih 'id' atau 'en'." ;;
				choice_invalid) echo "⚠️ Pilihan tidak dikenal: %s" ;;
				press_enter) echo "Tekan Enter untuk kembali ke menu..." ;;
				bye) echo "Sampai jumpa." ;;
				*) echo "$key" ;;
			esac
			;;
	esac
}

ensure_vault_dir() {
	mkdir -p "$VAULT_DIR"
	chmod 700 "$VAULT_DIR"
}

read_master_pass() {
	if [[ -z "${MASTER_PASS-}" ]]; then
		printf "Master password: "
		read -r -s MASTER_PASS || die "Gagal membaca password."
		echo
	fi
}

decrypt_vault() {
	ensure_vault_dir

	if [[ ! -f "$VAULT_FILE" ]]; then
		echo '{}' > "$TMP_FILE"
		return
	fi

	read_master_pass

	if ! openssl enc -aes-256-cbc -pbkdf2 -d -salt \
		-in "$VAULT_FILE" -out "$TMP_FILE" \
		-pass pass:"$MASTER_PASS" 2>/dev/null; then
		rm -f "$TMP_FILE"
		die "Gagal decrypt vault. Password salah atau file korup."
	fi
}

encrypt_vault() {
	read_master_pass

	if ! openssl enc -aes-256-cbc -pbkdf2 -salt \
		-in "$TMP_FILE" -out "$VAULT_FILE" \
		-pass pass:"$MASTER_PASS"; then
		die "Gagal encrypt vault."
	fi
}

check_deps() {
	local missing=()
	for bin in openssl jq oathtool; do
		if ! command -v "$bin" >/dev/null 2>&1; then
			missing+=("$bin")
		fi
	done

	if ((${#missing[@]} > 0)); then
		echo "❌ Dependensi belum terpasang: ${missing[*]}"
		echo "   Contoh install di Debian/Ubuntu/Kali:"
		echo "     sudo apt install openssl jq oathtool zip"
		echo
		echo "   Di Termux:"
		echo "     pkg install openssl-tool jq oathtool zip"
		exit 1
	fi
}

detect_default_host() {
	local preferred="${SAT_WEB_DEFAULT_HOST:-}"
	if [[ -n "$preferred" ]]; then
		printf "%s" "$preferred"
		return
	fi

	local candidate=""
	if command -v ip >/dev/null 2>&1; then
		candidate="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')"
	fi
	if [[ -z "$candidate" ]] && command -v hostname >/dev/null 2>&1; then
		candidate="$(hostname -I 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i!~/^127\\./) {print $i; exit}}')"
	fi

	if [[ -n "$candidate" && "$candidate" != "127.0.0.1" ]]; then
		local private="no"
		case "$candidate" in
			10.*|192.168.*|172.1[6-9].*|172.2[0-9].*|172.3[0-1].*|169.254.*|127.*)
				private="yes"
				;;
		esac
		if [[ "$private" == "no" ]]; then
			printf "%s" "$candidate"
			return
		fi
		if [[ -n "${SSH_CONNECTION-}" || -n "${SSH_CLIENT-}" || -n "${SSH_TTY-}" ]]; then
			printf "%s" "$candidate"
			return
		fi
	fi

	if [[ -n "${SSH_CONNECTION-}" || -n "${SSH_CLIENT-}" || -n "${SSH_TTY-}" ]]; then
		printf "0.0.0.0"
	else
		printf "127.0.0.1"
	fi
}

generate_totp_code() {
	local secret="$1" digits="$2" period="$3" algo="$4"
	local algo_flag=()

	case "${algo^^}" in
		SHA256) algo_flag=(--sha256) ;;
		SHA512) algo_flag=(--sha512) ;;
		*) algo_flag=() ;;
	esac

	oathtool --base32 --totp --digits="$digits" --time-step-size="$period" "${algo_flag[@]}" "$secret"
}

copy_to_clipboard() {
	local text="$1"

	if command -v termux-clipboard-set >/dev/null 2>&1; then
		printf "%s" "$text" | termux-clipboard-set
		echo "📋 Kode sudah dicopy ke clipboard (Termux)."
	elif command -v xclip >/dev/null 2>&1; then
		printf "%s" "$text" | xclip -selection clipboard
		echo "📋 Kode sudah dicopy ke clipboard (xclip)."
	elif command -v xsel >/dev/null 2>&1; then
		printf "%s" "$text" | xsel --clipboard --input
		echo "📋 Kode sudah dicopy ke clipboard (xsel)."
	else
		echo "ℹ️ Tidak ada utilitas clipboard (termux-clipboard-set/xclip/xsel)."
	fi
}

# Jalankan command tapi jangan biarkan set -e bikin script keluar dari menu
run_action() {
	set +e
	"$@"
	local rc=$?
	set -e
	return $rc
}

# -------------------------------------------------------------------
# Commands
# -------------------------------------------------------------------

cmd_help() {
	cat <<EOF
${APP_NAME}  v${APP_VERSION}

Usage:
  sat.sh init
      Inisialisasi vault OTP baru.

  sat.sh add [label]
      Tambah akun OTP baru.

  sat.sh update <label> [--new-label <nama>] [--issuer ..] [--account ..] [--secret ..] [--digits ..] [--period ..] [--algo ..]
      Edit label/issuer/account/secret tanpa membuat ulang.

  sat.sh list
      List semua OTP (label, issuer, account).

  sat.sh show <label>
      Lihat detail OTP tanpa menampilkan secret.

  sat.sh code <label> [--clip] [--live]
      Generate kode OTP untuk label.
      --clip : copy kode sekali ke clipboard (single mode).
      --live : mode live, kode auto-refresh tiap period (Ctrl+C untuk keluar).

  sat.sh codes
      Tampilkan seluruh kode OTP aktif + sisa detik.

  sat.sh delete <label>
      Hapus satu OTP dari vault.

  sat.sh portable [nama_bundle]
      Buat bundle portable (.zip), hapus vault lokal & folder kerja.

  sat.sh web [--port 8787] [--host 127.0.0.1] [--allow-network] [--token <secret>]
      Mode web UI + JSON API (default hanya localhost, tabel menampilkan kode live real-time).
      Fitur upload & scan QR (otomatis isi secret) membutuhkan utilitas 'zbarimg'.

  sat.sh web-start [opsi web]
      Jalankan Web UI di background agar tetap hidup setelah terminal ditutup.

  sat.sh web-stop
      Hentikan Web UI background yang dibuat oleh web-start.

  sat.sh web-status
      Lihat status Web UI background.

  sat.sh menu
      Buka menu interaktif (juga default kalau tanpa argumen).

Env:
  SAT_LANG=id|en       Pilih bahasa default (Indonesia/English) untuk menu & Web UI.
  SAT_OUTPUT=text|json Paksa output JSON (untuk API/otomasi).
  SAT_WEB_DEFAULT_HOST Default host untuk Web UI (override deteksi otomatis).

Catatan:
  Tambahkan --json pada list/show/code/codes/delete/add/update untuk output JSON (API).

Contoh:
  ./sat.sh init
  ./sat.sh add github-main
  ./sat.sh code github-main --clip
  ./sat.sh code discord-main --live
  ./sat.sh portable my_sat_backup_20251207
EOF
}

cmd_init() {
	check_deps
	ensure_vault_dir

	if [[ -f "$VAULT_FILE" ]]; then
		echo "ℹ️ Vault sudah ada di: $VAULT_FILE"
		return
	fi

	read_master_pass
	echo '{}' > "$TMP_FILE"
	encrypt_vault
	echo "✅ Vault baru dibuat di: $VAULT_FILE"
}

cmd_add() {
	check_deps
	local label="" issuer="" account="" secret="" digits="" period="" algo="SHA1" output="${SAT_OUTPUT:-text}"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--label)
				[[ $# -ge 2 ]] || die "--label perlu nilai"
				label="${2-}"; shift 2 ;;
			--issuer)
				[[ $# -ge 2 ]] || die "--issuer perlu nilai"
				issuer="${2-}"; shift 2 ;;
			--account)
				[[ $# -ge 2 ]] || die "--account perlu nilai"
				account="${2-}"; shift 2 ;;
			--secret)
				[[ $# -ge 2 ]] || die "--secret perlu nilai"
				secret="${2-}"; shift 2 ;;
			--digits)
				[[ $# -ge 2 ]] || die "--digits perlu nilai"
				digits="${2-}"; shift 2 ;;
			--period)
				[[ $# -ge 2 ]] || die "--period perlu nilai"
				period="${2-}"; shift 2 ;;
			--algo)
				[[ $# -ge 2 ]] || die "--algo perlu nilai"
				algo="${2-}"; shift 2 ;;
			--json)
				output="json"; shift ;;
			--)
				shift; break ;;
			*)
				if [[ -z "$label" ]]; then
					label="$1"
					shift
				else
					break
				fi
				;;
		esac
	done

	if [[ -z "$label" ]]; then
		printf "Label (contoh: github-main): "
		read -r label
	fi
	[[ -n "$label" ]] || die "Label tidak boleh kosong."

	if [[ -z "$issuer" ]]; then
		printf "Issuer (contoh: GitHub): "
		read -r issuer
	fi
	if [[ -z "$account" ]]; then
		printf "Account (email/username): "
		read -r account
	fi
	if [[ -z "$secret" ]]; then
		printf "Secret (BASE32, dari QR/website): "
		read -r secret
	fi

	if [[ -z "$digits" ]]; then
		printf "Digits [6]: "
		read -r digits || true
		digits="${digits:-6}"
	fi

	if [[ -z "$period" ]]; then
		printf "Period (detik) [30]: "
		read -r period || true
		period="${period:-30}"
	fi

	if ! [[ "$digits" =~ ^[0-9]+$ ]]; then
		digits=6
	fi
	if ! [[ "$period" =~ ^[0-9]+$ ]]; then
		period=30
	fi
	algo="${algo^^}"

	decrypt_vault

	jq --arg lbl "$label" \
	   --arg iss "$issuer" \
	   --arg acc "$account" \
	   --arg sec "$secret" \
	   --argjson digits "$digits" \
	   --argjson period "$period" \
	   --arg algo "$algo" \
	   '.[$lbl] = {issuer:$iss, account:$acc, secret:$sec, digits:$digits, period:$period, algo:$algo}' \
	   "$TMP_FILE" > "${TMP_FILE}.tmp"

	mv "${TMP_FILE}.tmp" "$TMP_FILE"
	encrypt_vault

	if [[ "$output" == "json" ]]; then
		require_cmd jq
		jq -n \
			--arg lbl "$label" \
			--arg issuer "$issuer" \
			--arg account "$account" \
			--arg algo "$algo" \
			--argjson digits "${digits:-6}" \
			--argjson period "${period:-30}" \
			'{
				label: $lbl,
				issuer: $issuer,
				account: $account,
				digits: $digits,
				period: $period,
				algo: $algo,
				status: "created"
			}'
	else
		echo "✅ OTP '$label' disimpan."
	fi

	rm -f "$TMP_FILE"
}

cmd_update() {
	check_deps
	local current_label="" new_label="" issuer="__UNSET__" account="__UNSET__" secret="__UNSET__" digits="" period="" algo="__UNSET__" output="${SAT_OUTPUT:-text}"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--label)
				[[ $# -ge 2 ]] || die "--label perlu nilai"
				current_label="${2-}"; shift 2 ;;
			--new-label|--rename)
				[[ $# -ge 2 ]] || die "--new-label perlu nilai"
				new_label="${2-}"; shift 2 ;;
			--issuer)
				[[ $# -ge 2 ]] || die "--issuer perlu nilai"
				issuer="${2-}"; shift 2 ;;
			--account)
				[[ $# -ge 2 ]] || die "--account perlu nilai"
				account="${2-}"; shift 2 ;;
			--secret)
				[[ $# -ge 2 ]] || die "--secret perlu nilai"
				secret="${2-}"; shift 2 ;;
			--digits)
				[[ $# -ge 2 ]] || die "--digits perlu nilai"
				digits="${2-}"; shift 2 ;;
			--period)
				[[ $# -ge 2 ]] || die "--period perlu nilai"
				period="${2-}"; shift 2 ;;
			--algo)
				[[ $# -ge 2 ]] || die "--algo perlu nilai"
				algo="${2-}"; shift 2 ;;
			--json)
				output="json"; shift ;;
			--)
				shift; break ;;
			*)
				if [[ -z "$current_label" ]]; then
					current_label="$1"
					shift
				else
					echo "⚠️  Argumen tidak dikenal: $1"
					shift
				fi
				;;
		esac
	done

	[[ -n "$current_label" ]] || die "Usage: $0 update <label> [--new-label <name>] [--issuer <issuer>] [--account <acc>] [--secret <base32>] [--digits <n>] [--period <s>] [--algo <ALGO>] [--json]"

	decrypt_vault

	local item
	item="$(jq -r --arg lbl "$current_label" '.[$lbl] // empty' "$TMP_FILE")"

	if [[ -z "$item" || "$item" == "null" ]]; then
		if [[ "$output" == "json" ]]; then
			printf '{"error":"not_found","label":"%s"}\n' "$current_label"
		else
			echo "❌ Label '$current_label' tidak ditemukan."
		fi
		rm -f "$TMP_FILE"
		return
	fi

	local target_label="$new_label"
	if [[ -z "$target_label" ]]; then
		target_label="$current_label"
	fi

	if [[ "$target_label" != "$current_label" ]]; then
		local exists
		exists="$(jq -r --arg lbl "$target_label" 'has($lbl)' "$TMP_FILE")"
		if [[ "$exists" == "true" ]]; then
			if [[ "$output" == "json" ]]; then
				printf '{"error":"label_exists","label":"%s"}\n' "$target_label"
			else
				echo "❌ Label baru '$target_label' sudah ada."
			fi
			rm -f "$TMP_FILE"
			return
		fi
	fi

	if [[ "$issuer" == "__UNSET__" ]]; then
		issuer="$(jq -r '.issuer // ""' <<<"$item")"
	fi
	if [[ "$account" == "__UNSET__" ]]; then
		account="$(jq -r '.account // ""' <<<"$item")"
	fi
	if [[ "$secret" == "__UNSET__" ]]; then
		secret="$(jq -r '.secret // ""' <<<"$item")"
	fi
	if [[ -z "$digits" ]]; then
		digits="$(jq -r '.digits // 6' <<<"$item")"
	fi
	if [[ -z "$period" ]]; then
		period="$(jq -r '.period // 30' <<<"$item")"
	fi
	if [[ "$algo" == "__UNSET__" ]]; then
		algo="$(jq -r '.algo // "SHA1"' <<<"$item")"
	fi
	algo="${algo:-SHA1}"
	algo="${algo^^}"

	if ! [[ "$digits" =~ ^[0-9]+$ ]]; then
		digits=6
	fi
	if ! [[ "$period" =~ ^[0-9]+$ ]]; then
		period=30
	fi

	jq --arg old "$current_label" \
	   --arg new "$target_label" \
	   --arg iss "$issuer" \
	   --arg acc "$account" \
	   --arg sec "$secret" \
	   --argjson digits "$digits" \
	   --argjson period "$period" \
	   --arg algo "$algo" \
	   '(if $old == $new then . else del(.[$old]) end)
	    | .[$new] = {issuer:$iss, account:$acc, secret:$sec, digits:$digits, period:$period, algo:$algo}' \
	   "$TMP_FILE" > "${TMP_FILE}.tmp"

	mv "${TMP_FILE}.tmp" "$TMP_FILE"
	encrypt_vault

	if [[ "$output" == "json" ]]; then
		require_cmd jq
		jq -n \
			--arg lbl "$target_label" \
			--arg old_lbl "$current_label" \
			--arg issuer "$issuer" \
			--arg account "$account" \
			--arg algo "$algo" \
			--argjson digits "${digits:-6}" \
			--argjson period "${period:-30}" \
			'{
				label: $lbl,
				old_label: $old_lbl,
				issuer: $issuer,
				account: $account,
				digits: $digits,
				period: $period,
				algo: $algo,
				status: "updated"
			}'
	else
		echo "✅ OTP '$current_label' diperbarui (label baru: '$target_label')."
	fi

	rm -f "$TMP_FILE"
}

cmd_list() {
	check_deps
	local output="${SAT_OUTPUT:-text}"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--json)
				output="json"
				;;
			*)
				echo "⚠️  Argumen tidak dikenal: $1"
				;;
		esac
		shift
	done
	decrypt_vault

	local count
	count=$(jq 'length' "$TMP_FILE")

	if [[ "$count" -eq 0 ]]; then
		if [[ "$output" == "json" ]]; then
			printf '{"entries":[]}\n'
		else
			echo "ℹ️ Vault masih kosong."
		fi
		rm -f "$TMP_FILE"
		return
	fi

	if [[ "$output" == "json" ]]; then
		require_cmd jq
		local payload
		payload="$(jq -c 'to_entries | map({label:.key, issuer:(.value.issuer//""), account:(.value.account//""), digits:(.value.digits//6), period:(.value.period//30), algo:(.value.algo//"SHA1")})' "$TMP_FILE")"
		printf '{"entries":%s}\n' "$payload"
	else
		printf "%-20s %-18s %s\n" "LABEL" "ISSUER" "ACCOUNT"
		printf "%-20s %-18s %s\n" "-----" "------" "-------"

		jq -r 'to_entries[] | "\(.key)\t\(.value.issuer)\t\(.value.account)"' "$TMP_FILE" |
		while IFS=$'\t' read -r k iss acc; do
			printf "%-20s %-18s %s\n" "$k" "$iss" "$acc"
		done
	fi

	rm -f "$TMP_FILE"
}

cmd_show() {
	check_deps
	local output="${SAT_OUTPUT:-text}"
	local label=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--json)
				output="json"
				;;
			*)
				if [[ -z "$label" ]]; then
					label="$1"
				fi
				;;
		esac
		shift
	done

	[[ -n "$label" ]] || die "Usage: $0 show <label> [--json]"

	decrypt_vault

	local item
	item="$(jq -r --arg lbl "$label" '.[$lbl] // empty' "$TMP_FILE")"

	if [[ -z "$item" || "$item" == "null" ]]; then
		if [[ "$output" == "json" ]]; then
			printf '{"error":"not_found","label":"%s"}\n' "$label"
		else
			echo "❌ Label '$label' tidak ditemukan."
		fi
		rm -f "$TMP_FILE"
		return
	fi

	if [[ "$output" == "json" ]]; then
		require_cmd jq
		jq -c --arg lbl "$label" \
			'{label:$lbl, issuer:(.issuer//""), account:(.account//""), digits:(.digits//6), period:(.period//30), algo:(.algo//"SHA1")}' <<<"$item"
	else
		echo "Label   : $label"
		echo "Issuer  : $(jq -r '.issuer' <<<"$item")"
		echo "Account : $(jq -r '.account' <<<"$item")"
		echo "Digits  : $(jq -r '.digits' <<<"$item")"
		echo "Period  : $(jq -r '.period' <<<"$item") detik"
		echo "Algo    : $(jq -r '.algo' <<<"$item")"
	fi

	rm -f "$TMP_FILE"
}

cmd_code() {
	check_deps

	local output="${SAT_OUTPUT:-text}"
	local label="${1-}"
	shift || true

	[[ -n "$label" ]] || die "Usage: $0 code <label> [--clip] [--live] [--json]"

	local clip="no"
	local mode="single"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--clip)
				clip="yes"
				;;
			--live|-l)
				mode="live"
				;;
			--json)
				output="json"
				;;
			*)
				echo "⚠️  Argumen tidak dikenal: $1"
				;;
		esac
		shift
	done

	if [[ "$output" == "json" && "$mode" == "live" ]]; then
		die "Mode live tidak didukung untuk output JSON."
	fi

	decrypt_vault

	local secret digits period algo
	secret="$(jq -r --arg lbl "$label" '.[$lbl].secret // empty' "$TMP_FILE")"

	if [[ -z "$secret" || "$secret" == "null" ]]; then
		if [[ "$output" == "json" ]]; then
			printf '{"error":"not_found","label":"%s"}\n' "$label"
		else
			echo "❌ Label '$label' tidak ditemukan."
		fi
		rm -f "$TMP_FILE"
		return
	fi

	digits="$(jq -r --arg lbl "$label" '.[$lbl].digits // 6' "$TMP_FILE")"
	period="$(jq -r --arg lbl "$label" '.[$lbl].period // 30' "$TMP_FILE")"
	algo="$(jq -r --arg lbl "$label" '.[$lbl].algo // "SHA1"' "$TMP_FILE")"

	rm -f "$TMP_FILE"

	if ! [[ "$digits" =~ ^[0-9]+$ ]]; then
		digits=6
	fi
	if ! [[ "$period" =~ ^[0-9]+$ ]]; then
		period=30
	fi
	algo="${algo^^}"

	if [[ "$mode" == "single" ]]; then
		local code now step next remaining
		now="$(date +%s)"
		step=$(( now / period ))
		next=$(( (step + 1) * period ))
		remaining=$(( next - now ))
		code="$(generate_totp_code "$secret" "$digits" "$period" "$algo")"

		if [[ "$output" == "json" ]]; then
			require_cmd python3
			python3 - "$label" "$code" "$period" "$digits" "$remaining" <<'PY'
import json, sys
lbl, code, period, digits, remaining = sys.argv[1:6]
print(json.dumps({
    "label": lbl,
    "code": code,
    "period": int(period),
    "digits": int(digits),
    "expires_in": int(remaining)
}))
PY
		else
			echo "Kode OTP untuk '$label' (period ${period}s, digits ${digits}): $code"

			if [[ "$clip" == "yes" ]]; then
				copy_to_clipboard "$code"
			fi
		fi
	else
		echo "🔄 Live mode untuk '$label' (period ${period}s, digits ${digits})."
		echo "   Tekan Ctrl+C untuk keluar."
		echo

		while true; do
			local now step next remaining code

			now="$(date +%s)"
			step=$(( now / period ))
			next=$(( (step + 1) * period ))
			remaining=$(( next - now ))

			code="$(generate_totp_code "$secret" "$digits" "$period" "$algo")"

			printf "\rKode: %s  | Refresh dalam: %2ds  " "$code" "$remaining"

			sleep 1
		done
	fi
}

cmd_codes() {
	check_deps
	local output="${SAT_OUTPUT:-text}"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--json)
				output="json"
				;;
			*)
				echo "⚠️  Argumen tidak dikenal: $1"
				;;
		esac
		shift
	done

	decrypt_vault

	local count
	count=$(jq 'length' "$TMP_FILE")

	if [[ "$count" -eq 0 ]]; then
		if [[ "$output" == "json" ]]; then
			printf '{"entries":[]}\n'
		else
			echo "ℹ️ Vault masih kosong."
		fi
		rm -f "$TMP_FILE"
		return
	fi

	local now
	now="$(date +%s)"

	if [[ "$output" == "json" ]]; then
		require_cmd python3
		python3 - "$TMP_FILE" "$now" <<'PY'
import json, subprocess, sys

path, now = sys.argv[1], int(sys.argv[2])
vault = json.load(open(path))
entries = []

for label, item in vault.items():
    secret = (item.get("secret") or "").strip()
    if not secret:
        continue
    digits = item.get("digits") or 6
    period = item.get("period") or 30
    algo = (item.get("algo") or "SHA1").upper()

    try:
        digits_int = int(digits)
    except Exception:
        digits_int = 6
    try:
        period_int = int(period)
    except Exception:
        period_int = 30

    step = now // period_int
    remaining = ((step + 1) * period_int) - now

    flags = []
    if algo == "SHA256":
        flags.append("--sha256")
    elif algo == "SHA512":
        flags.append("--sha512")

    args = [
        "oathtool",
        "--base32",
        "--totp",
        f"--digits={digits_int}",
        f"--time-step-size={period_int}",
        *flags,
        secret,
    ]
    proc = subprocess.run(args, capture_output=True, text=True)
    code = proc.stdout.strip() if proc.returncode == 0 else ""

    entries.append({
        "label": label,
        "issuer": item.get("issuer") or "",
        "account": item.get("account") or "",
        "digits": digits_int,
        "period": period_int,
        "algo": algo,
        "code": code,
        "expires_in": max(0, remaining),
    })

print(json.dumps({"entries": entries}))
PY
	else
		printf "%-20s %-12s %-10s %-10s\n" "LABEL" "CODE" "SISA(s)" "PERIOD"
		printf "%-20s %-12s %-10s %-10s\n" "-----" "----" "-------" "------"

		while IFS=$'\t' read -r label secret digits period algo; do
			[[ -n "$label" ]] || continue

			if [[ -z "$secret" || "$secret" == "null" ]]; then
				continue
			fi
			if ! [[ "$digits" =~ ^[0-9]+$ ]]; then
				digits=6
			fi
			if ! [[ "$period" =~ ^[0-9]+$ ]]; then
				period=30
			fi
			algo="${algo^^}"

			local step next remaining code

			step=$(( now / period ))
			next=$(( (step + 1) * period ))
			remaining=$(( next - now ))

			code="$(generate_totp_code "$secret" "$digits" "$period" "$algo")"
			printf "%-20s %-12s %-10s %-10s\n" "$label" "$code" "$remaining" "$period"
		done < <(jq -r 'to_entries[] | "\(.key)\t\(.value.secret)\t\(.value.digits//6)\t\(.value.period//30)\t\(.value.algo//"SHA1")"' "$TMP_FILE")
	fi

	rm -f "$TMP_FILE"
}

cmd_delete() {
	check_deps
	local label="" output="${SAT_OUTPUT:-text}" force="no"
	local msg_not_found="" msg_confirm="" msg_cancelled="" msg_deleted=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--json)
				output="json"
				force="yes"
				;;
			--yes|--force)
				force="yes"
				;;
			*)
				if [[ -z "$label" ]]; then
					label="$1"
				fi
				;;
		esac
		shift
	done

	[[ -n "$label" ]] || die "Usage: $0 delete <label> [--yes] [--json]"

	decrypt_vault

	if [[ "$SAT_LANG" == "en" ]]; then
		msg_not_found="❌ Label '%s' not found."
		msg_confirm="Delete '%s'? [y/N]: "
		msg_cancelled="Cancelled."
		msg_deleted="✅ '%s' deleted from vault."
	else
		msg_not_found="❌ Label '%s' tidak ditemukan."
		msg_confirm="Yakin hapus '%s'? [y/N]: "
		msg_cancelled="Dibatalkan."
		msg_deleted="✅ '%s' dihapus dari vault."
	fi

	local exists
	exists="$(jq -r --arg lbl "$label" 'has($lbl)' "$TMP_FILE")"

	if [[ "$exists" != "true" ]]; then
		if [[ "$output" == "json" ]]; then
			printf '{"error":"not_found","label":"%s"}\n' "$label"
	else
			printf "$msg_not_found\n" "$label"
		fi
		rm -f "$TMP_FILE"
		return
	fi

	if [[ "$force" != "yes" ]]; then
		printf "$msg_confirm" "$label"
		read -r ans

		if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
			echo "$msg_cancelled"
			rm -f "$TMP_FILE"
			return
		fi
	fi

	jq --arg lbl "$label" 'del(.[$lbl])' "$TMP_FILE" > "${TMP_FILE}.tmp"
	mv "${TMP_FILE}.tmp" "$TMP_FILE"
	encrypt_vault

	if [[ "$output" == "json" ]]; then
		printf '{"label":"%s","status":"deleted"}\n' "$label"
	else
		printf "$msg_deleted\n" "$label"
	fi
}

cmd_portable() {
	ensure_vault_dir

	if [[ ! -f "$VAULT_FILE" ]]; then
		die "Vault tidak ditemukan di '$VAULT_FILE'. Tidak ada yang bisa di-export."
	fi

	local bundle_name="${1-}"
	if [[ -z "$bundle_name" ]]; then
		bundle_name="sat_portable_$(date +%Y%m%d_%H%M%S)"
	fi

	local workdir="./$bundle_name"

	if [[ -e "$workdir" ]]; then
		die "Target directory '$workdir' sudah ada. Pilih nama lain."
	fi

	mkdir -p "$workdir" || die "Gagal membuat directory '$workdir'."

	local script_src="${BASH_SOURCE[0]:-$0}"

	if [[ -f "$script_src" ]]; then
		cp "$script_src" "$workdir/sat.sh" || die "Gagal menyalin script ke bundle."
	else
		echo "⚠️ Tidak dapat menemukan file script asli, hanya vault yang disalin."
	fi

	cp "$VAULT_FILE" "$workdir/otp.vault" || die "Gagal menyalin vault ke bundle."

	if ! command -v zip >/dev/null 2>&1; then
		die "Perintah 'zip' tidak ditemukan. Install dulu (apt/ pkg install zip)."
	fi

	zip -rq "${bundle_name}.zip" "$bundle_name" || die "Gagal membuat file zip."

	if command -v shred >/dev/null 2>&1; then
		shred -u "$VAULT_FILE"
	else
		rm -f "$VAULT_FILE"
	fi

	rm -rf "$workdir"

	echo "✅ Bundle portable dibuat: ${bundle_name}.zip"
	echo "ℹ️ Vault lokal sudah dihapus. Simpan zip ini baik-baik."
}

# -------------------------------------------------------------------
# Web UI / API
# -------------------------------------------------------------------

cmd_web() {
	check_deps
	require_cmd python3

	if [[ ! -f "$VAULT_FILE" ]]; then
		die "Vault tidak ditemukan di '$VAULT_FILE'. Jalankan init dulu."
	fi

	local host
	host="$(detect_default_host)"
	local port="8787"
	local token="$SAT_WEB_TOKEN"

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--host)
				[[ $# -ge 2 ]] || die "--host perlu nilai (contoh: 0.0.0.0 atau 127.0.0.1)"
				host="${2}"
				shift 2
				;;
			--port)
				[[ $# -ge 2 ]] || die "--port perlu angka (contoh: 8787)"
				port="${2}"
				shift 2
				;;
			--allow-network|--bind-any)
				host="0.0.0.0"
				shift
				;;
			--token)
				[[ $# -ge 2 ]] || die "--token perlu nilai"
				token="${2-}"
				shift 2
				;;
			*)
				echo "⚠️  Argumen tidak dikenal: $1"
				shift
				;;
		esac
	done

	read_master_pass
	export MASTER_PASS

	local display_host="$host"
	if [[ "$host" == "0.0.0.0" ]]; then
		if command -v ip >/dev/null 2>&1; then
			display_host="$(ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')"
		fi
		if [[ -z "$display_host" ]]; then
			display_host="$(hostname -I 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i!~/^127/) {print $i; exit}}')"
		fi
		display_host="${display_host:-0.0.0.0}"
	fi

	local script_path
	script_path="$(realpath "$0" 2>/dev/null || readlink -f "$0" 2>/dev/null || printf "%s" "$0")"

	echo "🌐 Menyalakan SAT web UI di http://${display_host}:${port}"
	if [[ "$host" == "0.0.0.0" && "$display_host" != "0.0.0.0" ]]; then
		echo "   (listen 0.0.0.0, akses via IP: http://${display_host}:${port})"
	fi
	if [[ "$host" == "0.0.0.0" ]]; then
		echo "⚠️ Web UI dibuka ke jaringan. Gunakan --token untuk proteksi."
	fi
	echo "Tekan Ctrl+C untuk berhenti."

	SAT_WEB_HOST="$host" SAT_WEB_PORT="$port" SAT_WEB_TOKEN="$token" SAT_WEB_SCRIPT="$script_path" SAT_WEB_DISPLAY_HOST="$display_host" \
	SAT_LANG="$SAT_LANG" MASTER_PASS="$MASTER_PASS" python3 - <<'PY'
import base64
import binascii
import http.server
import imghdr
import json
import os
import shutil
import subprocess
import tempfile
import urllib.parse

HOST = os.environ.get("SAT_WEB_HOST", "127.0.0.1")
PORT = int(os.environ.get("SAT_WEB_PORT", "8787"))
SCRIPT = os.environ.get("SAT_WEB_SCRIPT", "./sat.sh")
TOKEN = os.environ.get("SAT_WEB_TOKEN", "")
DISPLAY_HOST = os.environ.get("SAT_WEB_DISPLAY_HOST", "")
LANG = (os.environ.get("SAT_LANG") or "id").lower()

HTML_TEMPLATE = r"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>SAT Web UI</title>
  <style>
    :root {
      --bg: radial-gradient(circle at 18% 20%, rgba(14,165,233,0.25), transparent 60%),
             radial-gradient(circle at 82% 0%, rgba(167,139,250,0.25), transparent 55%),
             linear-gradient(135deg, #020617, #0f172a 55%, #111f3a);
      --panel: rgba(8,15,30,0.92);
      --panel-border: rgba(255,255,255,0.08);
      --accent: #38bdf8;
      --accent-2: #c084fc;
      --text: #f8fafc;
      --muted: #94a3b8;
      --danger: #fb7185;
      --shadow: 0 24px 68px rgba(2,6,23,0.55);
      --table-border: rgba(148,163,184,0.18);
      --surface-hover: rgba(56,189,248,0.08);
      --glow: rgba(56,189,248,0.35);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: "Inter", "JetBrains Mono", "SFMono-Regular", Consolas, monospace;
      background: var(--bg);
      color: var(--text);
      padding: clamp(16px, 3vw, 32px);
      animation: fadeIn 0.6s ease;
    }
    body.theme-light {
      --bg: linear-gradient(120deg, #cde9ff, #e7f6ff 55%, #d9ecff);
      --panel: rgba(255,255,255,0.94);
      --panel-border: rgba(14,116,144,0.18);
      --accent: #0284c7;
      --accent-2: #38bdf8;
      --text: #0f172a;
      --muted: #4b5563;
      --shadow: 0 18px 45px rgba(15,23,42,0.2);
      --table-border: rgba(199,226,255,0.85);
      --surface-hover: rgba(2,132,199,0.12);
      --glow: rgba(2,132,199,0.28);
    }
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(16px); }
      to { opacity: 1; transform: translateY(0); }
    }
    @keyframes floatSoft {
      0% { transform: translate3d(0,0,0); opacity: 0.85; }
      100% { transform: translate3d(0,12px,0); opacity: 0.65; }
    }
    .container {
      width: 100%;
      max-width: 1200px;
      margin: 0 auto;
      display: flex;
      flex-direction: column;
      gap: clamp(16px, 2vw, 24px);
    }
    .panel {
      background: var(--panel);
      border: 1px solid var(--panel-border);
      border-radius: 22px;
      padding: 24px;
      box-shadow: var(--shadow);
      position: relative;
      overflow: hidden;
      transition: transform 0.3s ease, box-shadow 0.3s ease, border-color 0.25s ease;
    }
    .panel::before {
      content: "";
      position: absolute;
      inset: 0;
      background: radial-gradient(circle at 0% 0%, rgba(56,189,248,0.18), transparent 60%);
      opacity: 0;
      transition: opacity 0.3s ease;
      pointer-events: none;
    }
    .panel:hover {
      transform: translateY(-6px);
      border-color: rgba(56,189,248,0.4);
      box-shadow: 0 32px 70px rgba(3,7,18,0.45);
    }
    .panel:hover::before { opacity: 1; }
    .hero {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      flex-wrap: wrap;
      gap: 20px;
    }
    .table-panel {
      overflow-x: auto;
    }
    #otpTable {
      min-width: 560px;
    }
    .hero::after {
      content: "";
      position: absolute;
      top: -60px;
      right: -45px;
      width: 210px;
      height: 210px;
      border-radius: 40%;
      background: radial-gradient(circle, rgba(192,132,252,0.3), transparent 70%);
      animation: floatSoft 6s ease-in-out infinite alternate;
    }
    h1 { font-size: 30px; margin: 0; letter-spacing: 0.04em; }
    h2 { margin: 0 0 16px; font-size: 20px; letter-spacing: 0.02em; }
    .pill {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 6px 14px;
      border-radius: 999px;
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.15);
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.12em;
    }
    body.theme-light .pill {
      background: rgba(2,132,199,0.08);
      border-color: rgba(2,132,199,0.2);
      color: #0369a1;
    }
    .stats {
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
      margin-top: 14px;
    }
    .stat-card {
      min-width: 150px;
      padding: 14px 18px;
      border-radius: 16px;
      border: 1px solid rgba(255,255,255,0.1);
      background: rgba(9,16,33,0.85);
      position: relative;
      overflow: hidden;
      transition: transform 0.3s ease, border 0.25s ease;
    }
    .stat-card::after {
      content: "";
      position: absolute;
      inset: 0;
      background: linear-gradient(120deg, rgba(56,189,248,0.16), transparent 70%);
      opacity: 0;
      transition: opacity 0.3s ease;
    }
    .stat-card:hover {
      transform: translateY(-3px);
      border-color: rgba(56,189,248,0.55);
    }
    .stat-card:hover::after { opacity: 1; }
    body.theme-light .stat-card {
      background: rgba(255,255,255,0.78);
      border-color: rgba(2,132,199,0.2);
    }
    .stat-label {
      font-size: 11px;
      text-transform: uppercase;
      letter-spacing: 0.12em;
      color: var(--muted);
    }
    .stat-value {
      font-size: 20px;
      font-weight: 700;
      margin-top: 6px;
    }
    .hero-controls { text-align: right; min-width: 270px; }
    .control-stack {
      display: flex;
      flex-direction: column;
      gap: 12px;
      align-items: flex-end;
    }
    label {
      font-size: 13px;
      color: var(--muted);
      display: block;
      margin-bottom: 6px;
    }
    input, button, .file-button {
      font-family: inherit;
      border-radius: 12px;
      border: 1px solid rgba(255,255,255,0.12);
      background: rgba(255,255,255,0.04);
      color: var(--text);
      padding: 11px 14px;
      width: 100%;
      transition: border 0.2s ease, transform 0.15s ease, background 0.2s ease;
    }
    input:focus {
      outline: none;
      border-color: var(--accent);
      background: rgba(255,255,255,0.08);
      transform: translateY(-1px);
    }
    body.theme-light input {
      background: rgba(2,132,199,0.08);
      border-color: rgba(2,132,199,0.18);
    }
    .file-input {
      display: flex;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
    }
    .file-button {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
      border-style: dashed;
      border-color: rgba(255,255,255,0.25);
    }
    .file-button:hover {
      border-style: solid;
      border-color: var(--accent);
      transform: translateY(-1px);
    }
    body.theme-light .file-button {
      border-color: rgba(2,132,199,0.35);
      background: rgba(2,132,199,0.08);
    }
    .file-name {
      font-size: 12px;
      color: var(--muted);
      min-width: 140px;
    }
    button {
      cursor: pointer;
      border: none;
      background: linear-gradient(120deg, var(--accent), var(--accent-2));
      color: #061229;
      font-weight: 700;
      box-shadow: 0 18px 38px rgba(56,189,248,0.35);
      position: relative;
      overflow: hidden;
    }
    button::after {
      content: "";
      position: absolute;
      inset: 0;
      background: radial-gradient(circle, rgba(255,255,255,0.35), transparent 60%);
      opacity: 0;
      transition: opacity 0.35s ease;
    }
    button:hover::after { opacity: 1; }
    button:hover { transform: translateY(-2px); }
    button:active {
      transform: translateY(0);
      box-shadow: 0 12px 24px rgba(56,189,248,0.3);
    }
    .ghost {
      background: transparent;
      border: 1px solid rgba(255,255,255,0.2);
      color: var(--text);
      box-shadow: none;
    }
    body.theme-light .ghost {
      border-color: rgba(2,132,199,0.25);
    }
    .actions { display: flex; gap: 12px; flex-wrap: wrap; }
    .grid {
      display: grid;
      grid-template-columns: minmax(0, 1.4fr) minmax(280px, 0.9fr);
      gap: clamp(14px, 2vw, 24px);
      align-items: stretch;
    }
    @media (min-width: 1400px) {
      .container { max-width: 1400px; }
      .grid { grid-template-columns: minmax(0, 1.3fr) minmax(320px, 1fr); }
      .panel { padding: 28px; }
      h1 { font-size: 32px; }
    }
    @media (max-width: 1280px) {
      .grid {
        grid-template-columns: minmax(0, 1fr);
      }
      .hero-controls { text-align: left; align-items: flex-start; min-width: 100%; }
      .control-stack { align-items: flex-start; width: 100%; }
    }
    @media (max-width: 768px) {
      body { padding: 14px; }
      .container { gap: 16px; }
      .hero { flex-direction: column; }
      .hero-controls { width: 100%; }
      .control-stack > div { width: 100% !important; }
      table, thead, tbody, th, td, tr { display: block; }
      thead { display: none; }
      tbody tr { margin-bottom: 12px; padding: 12px; border: 1px solid var(--panel-border); border-radius: 14px; }
      td { border: none; padding: 6px 0; }
      .code-chip { width: 100%; justify-content: center; }
      .countdown { justify-content: space-between; }
      .actions { flex-direction: column; }
      #otpTable { min-width: 100%; }
    }
    @media (max-width: 600px) {
      h1 { font-size: 24px; }
      h2 { font-size: 18px; }
      .stat-card { width: 100%; }
      input, button, .file-button { padding: 10px 12px; font-size: 14px; }
      .file-input { flex-direction: column; align-items: flex-start; }
      .theme-toggle { justify-content: flex-start; }
    }
    table {
      width: 100%;
      border-collapse: collapse;
      border-radius: 16px;
      overflow: hidden;
    }
    thead {
      background: rgba(255,255,255,0.03);
      backdrop-filter: blur(12px);
    }
    th, td {
      text-align: left;
      padding: 12px;
      border-bottom: 1px solid var(--table-border);
    }
    th {
      font-size: 12px;
      letter-spacing: 0.08em;
      color: var(--muted);
      text-transform: uppercase;
    }
    tbody tr {
      transition: background 0.25s ease, transform 0.15s ease;
    }
    tbody tr:hover {
      background: var(--surface-hover);
      transform: translateX(4px);
    }
    .tag {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 12px;
      border-radius: 999px;
      background: rgba(56,189,248,0.15);
      color: var(--accent);
      font-weight: 600;
    }
    .muted { color: var(--muted); font-size: 13px; }
    .tiny { font-size: 12px; }
    .code-chip {
      display: inline-flex;
      align-items: center;
      padding: 10px 14px;
      border-radius: 12px;
      background: rgba(56,189,248,0.2);
      color: #e0f2fe;
      font-size: 18px;
      letter-spacing: 1px;
    }
    body.theme-light .code-chip { color: #0f172a; }
    .countdown {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      font-variant-numeric: tabular-nums;
    }
    .countdown-ring {
      --progress: 0deg;
      --ring-color: var(--accent);
      position: relative;
      width: 28px;
      height: 28px;
      border-radius: 50%;
      background: conic-gradient(var(--ring-color) var(--progress, 0deg), rgba(255,255,255,0.15) var(--progress, 0deg));
      box-shadow: inset 0 0 8px rgba(0,0,0,0.45), 0 0 12px var(--glow);
      transition: background 0.4s ease, box-shadow 0.4s ease;
    }
    .countdown-ring::after {
      content: "";
      position: absolute;
      inset: 5px;
      border-radius: 50%;
      background: var(--panel);
      transition: background 0.3s ease;
    }
        .theme-toggle {
      margin-top: 6px;
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
      justify-content: flex-end;
    }
    .theme-switch {
      display: inline-flex;
      align-items: center;
      gap: 10px;
      padding: 6px 12px;
      border-radius: 999px;
      border: 1px solid rgba(255,255,255,0.18);
      background: rgba(255,255,255,0.05);
      color: var(--muted);
      cursor: pointer;
      transition: background 0.35s ease, border 0.35s ease, color 0.35s ease, transform 0.3s ease;
    }
    body.theme-light .theme-switch {
      border: 1px solid rgba(2,132,199,0.25);
      background: rgba(2,132,199,0.08);
    }
    .switch-track {
      width: 54px;
      height: 28px;
      border-radius: 999px;
      position: relative;
      overflow: hidden;
      background: linear-gradient(120deg, rgba(255,255,255,0.15), rgba(255,255,255,0.3));
    }
    .switch-track::after {
      content: "";
      position: absolute;
      inset: 0;
      background: radial-gradient(circle, rgba(255,255,255,0.45), transparent 65%);
      opacity: 0;
      transition: opacity 0.35s ease;
    }
    .theme-switch:hover .switch-track::after { opacity: 0.9; }
    body.theme-light .switch-track {
      background: linear-gradient(120deg, rgba(2,132,199,0.25), rgba(2,132,199,0.45));
    }
    .switch-thumb {
      position: absolute;
      top: 4px;
      left: 4px;
      width: 20px;
      height: 20px;
      border-radius: 50%;
      background: var(--accent);
      box-shadow: 0 6px 12px rgba(56,189,248,0.4);
      transition: transform 0.35s cubic-bezier(0.4, 0, 0.2, 1), background 0.3s ease;
    }
    .theme-switch[data-mode="light"] .switch-thumb { transform: translateX(24px); }
    .switch-text { font-size: 12px; font-weight: 600; color: var(--text); }
    .table-note { margin: 6px 0 10px; }
    .lang-select-wrap label { margin-bottom: 4px; display: block; }
    .lang-select {
      display: flex;
      align-items: center;
      gap: 8px;
      border: 1px solid rgba(255,255,255,0.15);
      border-radius: 12px;
      padding: 4px 10px;
      background: rgba(255,255,255,0.04);
      transition: border 0.3s ease, background 0.3s ease, transform 0.2s ease;
    }
    .lang-select:hover {
      border-color: var(--accent);
      transform: translateY(-1px);
    }
    body.theme-light .lang-select {
      border-color: rgba(2,132,199,0.2);
      background: rgba(2,132,199,0.08);
    }
    .lang-flag { font-size: 18px; }
    .lang-select select {
      appearance: none;
      background: transparent;
      border: none;
      color: var(--text);
      font-size: 13px;
      font-weight: 600;
      width: 100%;
      padding-right: 18px;
      cursor: pointer;
    }
    .lang-select select:focus { outline: none; }
    .lang-select::after {
      content: "▾";
      font-size: 12px;
      color: var(--muted);
    }
.table-note { margin: 6px 0 10px; }
    .lang-toggle {
      display: inline-flex;
      gap: 8px;
      padding: 4px;
      border-radius: 999px;
      border: 1px solid rgba(255,255,255,0.15);
      background: rgba(255,255,255,0.05);
    }
    body.theme-light .lang-toggle {
      border-color: rgba(2,132,199,0.25);
      background: rgba(2,132,199,0.08);
    }
    .lang-option {
      min-width: 78px;
      padding: 8px 14px;
      border-radius: 999px;
      border: none;
      background: transparent;
      color: var(--muted);
      font-weight: 600;
      cursor: pointer;
      transition: background 0.2s ease, color 0.2s ease, transform 0.15s ease;
    }
    .lang-option:hover { color: var(--text); transform: translateY(-1px); }
    .lang-option.active {
      background: linear-gradient(120deg, var(--accent), var(--accent-2));
      color: #031225;
      box-shadow: 0 12px 22px rgba(56,189,248,0.35);
    }
  </style></style>
</head>
<body>
  <div class="container">
    <div class="panel hero">
      <div class="hero-info">
        <div class="pill">SAT v1.0.0</div>
        <h1>SAT Web UI</h1>
        <div class="muted" data-i18n="subtitle">Silent Authenticator Tool · vault lokal terenkripsi · host default 127.0.0.1</div>
        <div class="stats">
          <div class="stat-card">
            <div class="stat-label" data-i18n="hostText">Host</div>
            <div class="stat-value" id="hostLabel">127.0.0.1</div>
          </div>
          <div class="stat-card">
            <div class="stat-label" data-i18n="portText">Port</div>
            <div class="stat-value" id="portLabel">8787</div>
          </div>
        </div>
      </div>
      <div class="hero-controls">
        <div class="control-stack">
          <div style="width:220px;">
            <label for="tokenInput" data-i18n="tokenLabel">Token (opsional):</label>
            <input id="tokenInput" placeholder="X-SAT-Token" />
          </div>
          <div style="width:220px;" class="lang-select-wrap">
            <label data-i18n="langLabel">Language:</label>
            <div class="lang-select">
              <span class="lang-flag" id="langFlag">🇮🇩</span>
              <select id="langSelect">
                <option value="id">🇮🇩 Indonesia</option>
                <option value="en">🇬🇧 English</option>
              </select>
            </div>
          </div>
          <div style="width:220px;">
            <label data-i18n="themeLabel">Mode:</label>
            <div class="theme-toggle" style="justify-content:flex-start;">
              <button type="button" id="themeToggle" class="theme-switch" data-mode="dark">
                <span class="switch-track"><span class="switch-thumb"></span></span>
                <span class="switch-text" data-theme-text>Mode Malam</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  <div class="grid">
    <div class="panel table-panel">
      <h2 data-i18n="listTitle">Daftar OTP</h2>
      <div class="muted table-note" id="listInfo" data-i18n="loading">Memuat...</div>
      <table id="otpTable">
        <thead>
          <tr><th data-i18n="thLabel">Label</th><th data-i18n="thCode">Kode</th><th data-i18n="thRemain">Sisa</th><th data-i18n="thIssuer">Issuer</th><th data-i18n="thAccount">Account</th><th></th></tr>
        </thead>
        <tbody></tbody>
      </table>
    </div>
    <div class="panel">
      <h2 id="formTitle" data-i18n="formTitleAdd">Tambah OTP</h2>
      <div id="formMode" class="muted" style="margin-bottom:8px;" data-i18n="formModeNew">Tambah OTP baru</div>
      <form id="addForm">
        <div class="row">
          <div><label class="muted" data-i18n="labelLabel">Label</label><input required id="label" placeholder="github-main" /></div>
          <div><label class="muted" data-i18n="issuerLabel">Issuer</label><input id="issuer" placeholder="GitHub" /></div>
        </div>
        <div class="row" style="margin-top:10px;">
          <div><label class="muted" data-i18n="accountLabel">Account</label><input id="account" placeholder="email/username" /></div>
          <div><label class="muted" data-i18n="secretLabel">Secret (BASE32)</label><input id="secret" placeholder="BASE32" /></div>
        </div>
        <div style="margin-top:10px;">
          <label class="muted" data-i18n="qrLabel">Scan QR (opsional)</label>
          <div class="row" style="gap:8px; align-items:flex-end;">
            <div style="flex:2; min-width:200px;">
              <div class="file-input">
                <input type="file" id="qrFile" accept="image/*" style="display:none;" />
                <label for="qrFile" class="file-button" data-i18n="uploadFile">Unggah berkas</label>
                <span class="file-name" id="qrFileName" data-i18n="noFile">Tidak ada berkas</span>
              </div>
            </div>
            <div style="flex:1; min-width:140px;"><button type="button" id="scanQrBtn" class="ghost" style="padding:10px 14px;" data-i18n="qrScanBtn">Scan QR</button></div>
          </div>
          <div class="muted tiny" data-i18n="qrHint">Kosongkan secret lalu unggah QR (PNG/JPG) untuk mengisi otomatis.</div>
          <div class="tiny" id="qrStatus"></div>
        </div>
        <div class="row" style="margin-top:10px;">
          <div><label class="muted" data-i18n="digitsLabel">Digits</label><input id="digits" type="number" min="6" max="10" placeholder="6" /></div>
          <div><label class="muted" data-i18n="periodLabel">Period (s)</label><input id="period" type="number" min="15" max="90" placeholder="30" /></div>
          <div><label class="muted" data-i18n="algoLabel">Algo</label><input id="algo" placeholder="SHA1" /></div>
        </div>
        <div class="actions" style="margin-top:14px; justify-content:flex-start;">
          <button id="submitBtn" type="submit" style="padding:10px 14px;" data-i18n="btnSave">Simpan</button>
          <button id="cancelEdit" type="button" class="ghost" style="padding:10px 14px; display:none;" data-i18n="btnCancel">Batal edit</button>
        </div>
      </form>
      <div id="message" class="muted"></div>
    </div>
  </div>
  <div class="panel" style="margin-top:14px;">
    <h2 data-i18n="liveTitle">Live Kode OTP</h2>
    <div id="codeStatus" class="muted" data-i18n="liveDesc">Kode OTP tampil langsung di tabel dan diperbarui otomatis tiap detik.</div>
  </div>
  </div>
  <script>
    const PRESET_LANG = "__LANG__";
    const hostLabel = document.getElementById('hostLabel');
    const portLabel = document.getElementById('portLabel');
    const tokenInput = document.getElementById('tokenInput');
    const langSelect = document.getElementById('langSelect');
    const langFlag = document.getElementById('langFlag');
    const LANG_FLAGS = { id: '🇮🇩', en: '🇬🇧' };
    const themeToggle = document.getElementById('themeToggle');
    const themeText = document.querySelector('[data-theme-text]');
    const presetHost = "__HOST_LABEL__";
    hostLabel.textContent = presetHost || location.hostname || "127.0.0.1";
    portLabel.textContent = location.port || "8787";
    const tokenParams = new URLSearchParams(location.search);
    const urlToken = (tokenParams.get('token') || "").trim();
    let clientToken = urlToken || localStorage.getItem('satToken') || "";
    if (urlToken) {
      localStorage.setItem('satToken', urlToken);
      tokenParams.delete('token');
      const nextQuery = tokenParams.toString();
      history.replaceState(null, "", `${location.pathname}${nextQuery ? `?${nextQuery}` : ""}${location.hash}`);
    }
    if (clientToken) tokenInput.value = clientToken;
    tokenInput.addEventListener('change', () => {
      clientToken = tokenInput.value.trim();
      if (clientToken) {
        localStorage.setItem('satToken', clientToken);
      } else {
        localStorage.removeItem('satToken');
      }
    });
    const msg = (text, isError = false) => {
      const el = document.getElementById('message');
      el.textContent = text || '';
      el.style.color = isError ? '#fca5a5' : '#9ca3af';
    };
    const codeStatus = document.getElementById('codeStatus');
    const setCodeStatus = (text, isError = false) => {
      codeStatus.textContent = text;
      codeStatus.style.color = isError ? '#fca5a5' : '#9ca3af';
    };
    const addForm = document.getElementById('addForm');
    const submitBtn = document.getElementById('submitBtn');
    const cancelEditBtn = document.getElementById('cancelEdit');
    const formTitleEl = document.getElementById('formTitle');
    const formMode = document.getElementById('formMode');
    const labelInput = document.getElementById('label');
    const issuerInput = document.getElementById('issuer');
    const accountInput = document.getElementById('account');
    const secretInput = document.getElementById('secret');
    const digitsInput = document.getElementById('digits');
    const periodInput = document.getElementById('period');
    const algoInput = document.getElementById('algo');
    const qrFileInput = document.getElementById('qrFile');
    const scanQrBtn = document.getElementById('scanQrBtn');
    const qrStatus = document.getElementById('qrStatus');
    const qrFileName = document.getElementById('qrFileName');
    const headers = () => {
      const h = { 'Content-Type': 'application/json' };
      if (clientToken) h['X-SAT-Token'] = clientToken;
      return h;
    };
    const THEME_KEY = 'satThemeMode';
    let themeMode = (localStorage.getItem(THEME_KEY) || 'dark').toLowerCase() === 'light' ? 'light' : 'dark';
    const setThemeText = () => {
      if (!themeText) return;
      themeText.textContent = themeMode === 'light' ? t('themeLight') : t('themeDark');
    };
    const applyThemeMode = () => {
      const body = document.body;
      if (body) {
        body.classList.toggle('theme-light', themeMode === 'light');
        body.classList.toggle('theme-dark', themeMode !== 'light');
      }
      if (themeToggle) {
        themeToggle.setAttribute('data-mode', themeMode);
      }
      setThemeText();
    };
    if (themeToggle) {
      themeToggle.addEventListener('click', () => {
        themeMode = themeMode === 'light' ? 'dark' : 'light';
        localStorage.setItem(THEME_KEY, themeMode);
        applyThemeMode();
      });
    }
    const rootStyles = getComputedStyle(document.documentElement);
    const DEFAULT_ACCENT = (rootStyles.getPropertyValue('--accent') || '#22d3ee').trim() || '#22d3ee';
    const WARN_ACCENT = '#fde047';
    const DANGER_ACCENT = '#f87171';
    const LANGS = {
      id: {
        subtitle: "Silent Authenticator Tool · vault lokal terenkripsi · host default 127.0.0.1",
        hostText: "Host:",
        portText: "Port:",
        tokenLabel: "Token (opsional):",
        themeLabel: "Mode:",
        langLabel: "Bahasa:",
        langId: "Indonesia",
        langEn: "Inggris",
        listTitle: "Daftar OTP",
        loading: "Memuat...",
        thLabel: "Label",
        thCode: "Kode",
        thRemain: "Sisa",
        thIssuer: "Issuer",
        thAccount: "Account",
        formTitleAdd: "Tambah OTP",
        formTitleEdit: "Edit OTP",
        formModeNew: "Tambah OTP baru",
        formModeEdit: "Edit '__LABEL__' (secret bisa dikosongkan)",
        labelLabel: "Label",
        issuerLabel: "Issuer",
        accountLabel: "Account",
        secretLabel: "Secret (BASE32)",
        digitsLabel: "Digits",
        periodLabel: "Durasi (d)",
        algoLabel: "Algo",
        qrLabel: "Scan QR (opsional)",
        qrHint: "Kosongkan secret lalu unggah QR (PNG/JPG) untuk mengisi otomatis.",
        qrScanBtn: "Scan QR",
        qrNoFile: "Pilih file QR terlebih dahulu.",
        uploadFile: "Unggah berkas",
        noFile: "Tidak ada berkas",
        qrScanning: "Memindai QR...",
        qrScanFail: "Gagal memindai QR.",
        qrScanSuccess: "Secret diisi dari QR.",
        qrScannerMissing: "Scanner QR di server belum tersedia (install zbarimg).",
        qrInvalidImage: "File gambar tidak valid.",
        qrNotOtp: "QR tidak berformat otpauth.",
        qrNoSecret: "QR tidak memiliki secret.",
        themeDark: "Mode Malam",
        themeLight: "Mode Siang",
        btnSave: "Simpan",
        btnUpdate: "Update",
        btnCancel: "Batal edit",
        btnEdit: "Edit",
        btnDelete: "Hapus",
        listEmpty: "Vault kosong",
        listCount: "__N__ entry · kode live",
        liveTitle: "Live Kode OTP",
        liveDesc: "Kode OTP tampil langsung di tabel dan diperbarui otomatis tiap detik.",
        addSuccess: "OTP '__LABEL__' disimpan.",
        updateSuccess: "OTP '__LABEL__' diperbarui.",
        labelRequired: "Label wajib diisi.",
        secretRequired: "Secret wajib diisi untuk entri baru (isi manual atau scan QR).",
        loadFail: "Gagal memuat daftar",
        codeFail: "Gagal memuat kode",
        noCodes: "Tidak ada kode aktif.",
        syncStatus: "Kode live · sinkron __TIME__",
        vaultEmptyLive: "Vault kosong. Tambah entry untuk melihat kode live.",
        deleteAsk: "Hapus '__LABEL__'?",
        deleteSuccess: "Label '__LABEL__' dihapus.",
        deleteFail: "Gagal hapus",
        opFail: "Operasi gagal",
        editMode: "Mode edit untuk '__LABEL__'."
      },
      en: {
        subtitle: "Silent Authenticator Tool · encrypted local vault · default host 127.0.0.1",
        hostText: "Host:",
        portText: "Port:",
        tokenLabel: "Token (optional):",
        themeLabel: "Theme:",
        langLabel: "Language:",
        langId: "Indonesian",
        langEn: "English",
        listTitle: "OTP List",
        loading: "Loading...",
        thLabel: "Label",
        thCode: "Code",
        thRemain: "Left",
        thIssuer: "Issuer",
        thAccount: "Account",
        formTitleAdd: "Add OTP",
        formTitleEdit: "Edit OTP",
        formModeNew: "Add new OTP",
        formModeEdit: "Edit '__LABEL__' (secret can stay empty)",
        labelLabel: "Label",
        issuerLabel: "Issuer",
        accountLabel: "Account",
        secretLabel: "Secret (BASE32)",
        digitsLabel: "Digits",
        periodLabel: "Period (s)",
        algoLabel: "Algo",
        qrLabel: "Scan QR (optional)",
        qrHint: "Leave secret empty and upload a QR image (PNG/JPG) to autofill.",
        qrScanBtn: "Scan QR",
        qrNoFile: "Select a QR image first.",
        uploadFile: "Upload file",
        noFile: "No file selected",
        qrScanning: "Scanning QR...",
        qrScanFail: "Failed to scan QR.",
        qrScanSuccess: "Secret filled from QR.",
        qrScannerMissing: "QR scanner is not available on the server (install zbarimg).",
        qrInvalidImage: "Invalid image file.",
        qrNotOtp: "QR is not an otpauth link.",
        qrNoSecret: "QR code does not contain a secret.",
        themeDark: "Night Mode",
        themeLight: "Day Mode",
        btnSave: "Save",
        btnUpdate: "Update",
        btnCancel: "Cancel edit",
        btnEdit: "Edit",
        btnDelete: "Delete",
        listEmpty: "Vault is empty",
        listCount: "__N__ entries · live codes",
        liveTitle: "Live OTP Codes",
        liveDesc: "OTP codes show in table and auto-refresh every second.",
        addSuccess: "OTP '__LABEL__' saved.",
        updateSuccess: "OTP '__LABEL__' updated.",
        labelRequired: "Label is required.",
        secretRequired: "Secret is required for new entries (either type it or scan a QR).",
        loadFail: "Failed to load list",
        codeFail: "Failed to load codes",
        noCodes: "No active codes.",
        syncStatus: "Live codes · synced at __TIME__",
        vaultEmptyLive: "Vault is empty. Add an entry to see live codes.",
        deleteAsk: "Delete '__LABEL__'?",
        deleteSuccess: "Label '__LABEL__' deleted.",
        deleteFail: "Failed to delete",
        opFail: "Operation failed",
        editMode: "Edit mode for '__LABEL__'."
      }
    };
    const storedLang = (localStorage.getItem('satLang') || '').toLowerCase();
    let lang = storedLang || PRESET_LANG.toLowerCase() || 'id';
    if (!LANGS[lang]) lang = 'id';
    const t = (key, params = {}) => {
      let txt = (LANGS[lang] && LANGS[lang][key]) || key;
      Object.entries(params).forEach(([k, v]) => {
        txt = txt.replace(new RegExp(`__${k}__`, 'g'), v);
      });
      return txt;
    };
    const updateLangUI = () => {
      if (langSelect) {
        langSelect.value = lang;
        Array.from(langSelect.options).forEach(opt => {
          const value = (opt.value || '').toLowerCase();
          const labelKey = value === 'id' ? 'langId' : 'langEn';
          opt.textContent = t(labelKey);
        });
      }
      if (langFlag) {
        langFlag.textContent = LANG_FLAGS[lang] || '🌐';
      }
    };
    const applyLang = () => {
      document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        el.textContent = t(key);
      });
      submitBtn.textContent = editingLabel ? t('btnUpdate') : t('btnSave');
      formMode.textContent = editingLabel ? t('formModeEdit', { LABEL: editingLabel }) : t('formModeNew');
      if (formTitleEl) formTitleEl.textContent = editingLabel ? t('formTitleEdit') : t('formTitleAdd');
      codeStatus.textContent = t('liveDesc');
      document.title = "SAT Web UI";
      setThemeText();
      updateLangUI();
      updateQrFileName();
    };
    if (langSelect) {
      langSelect.addEventListener('change', () => {
        const value = (langSelect.value || '').toLowerCase();
        if (!value || value === lang || !LANGS[value]) {
          langSelect.value = lang;
          return;
        }
        lang = value;
        localStorage.setItem('satLang', lang);
        applyLang();
        renderList(entriesCache);
        if (entriesCache.length) {
          refreshCodes();
        } else {
          clearInterval(codeTimer);
          setCodeStatus(t('vaultEmptyLive'));
        }
      });
    }
    const api = async (path, options = {}) => {
      const res = await fetch(path, { ...options, headers: { ...(options.headers || {}), ...headers() } });
      const data = await res.json().catch(() => ({}));
      return { ok: res.ok, data };
    };
    const setQrStatus = (text, isError = false) => {
      if (!qrStatus) return;
      qrStatus.textContent = text || '';
      qrStatus.style.color = isError ? '#fca5a5' : '#9ca3af';
    };
    const updateQrFileName = () => {
      if (!qrFileName) return;
      const name = (qrFileInput && qrFileInput.files && qrFileInput.files[0] && qrFileInput.files[0].name) || "";
      qrFileName.textContent = name || t('noFile');
    };
    const fileToBase64 = (file) => new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => {
        const result = reader.result || '';
        const parts = String(result).split(',');
        resolve(parts.length > 1 ? parts.pop() : result);
      };
      reader.onerror = () => reject(new Error('read_error'));
      reader.readAsDataURL(file);
    });
    const qrErrorKey = (code) => {
      const map = {
        image_required: 'qrNoFile',
        invalid_image: 'qrInvalidImage',
        scanner_missing: 'qrScannerMissing',
        scan_failed: 'qrScanFail',
        scan_empty: 'qrScanFail',
        no_otpauth: 'qrNotOtp',
        secret_missing: 'qrNoSecret',
      };
      return map[code] || 'qrScanFail';
    };
    if (qrFileInput) {
      qrFileInput.addEventListener('change', updateQrFileName);
    }
    if (scanQrBtn && qrFileInput) {
      scanQrBtn.addEventListener('click', async () => {
        if (!qrFileInput.files.length) {
          setQrStatus(t('qrNoFile'), true);
          return;
        }
        scanQrBtn.disabled = true;
        setQrStatus(t('qrScanning'));
        try {
          const base64 = await fileToBase64(qrFileInput.files[0]);
          const res = await api('/api/scan_qr', { method: 'POST', body: JSON.stringify({ image: base64 }) });
          if (!res.ok) {
            setQrStatus(t(qrErrorKey(res.data.error)), true);
            return;
          }
          const data = res.data || {};
          if (data.secret) secretInput.value = data.secret;
          if (!labelInput.value && data.label) labelInput.value = data.label;
          if (!issuerInput.value && data.issuer) issuerInput.value = data.issuer;
          if (!accountInput.value && data.account) accountInput.value = data.account;
          if (!digitsInput.value && data.digits) digitsInput.value = data.digits;
          if (!periodInput.value && data.period) periodInput.value = data.period;
          if (!algoInput.value && data.algo) algoInput.value = data.algo;
          setQrStatus(t('qrScanSuccess'));
          msg(t('qrScanSuccess'));
        } catch (err) {
          setQrStatus(t('qrScanFail'), true);
        } finally {
          scanQrBtn.disabled = false;
        }
      });
    }
    let entriesCache = [];
    let rowRefs = {};
    let editingLabel = "";
    let codeState = {};
    let codeTimer = null;
    let refreshingCodes = false;
    const resetForm = () => {
      addForm.reset();
      editingLabel = "";
      submitBtn.textContent = t('btnSave');
      cancelEditBtn.style.display = "none";
      formMode.textContent = t('formModeNew');
      if (formTitleEl) formTitleEl.textContent = t('formTitleAdd');
      msg("");
      if (qrFileInput) {
        qrFileInput.value = "";
      }
      updateQrFileName();
      setQrStatus("");
    };
    cancelEditBtn.addEventListener('click', () => {
      resetForm();
    });
    const renderList = (entries) => {
      const tbody = document.querySelector('#otpTable tbody');
      tbody.innerHTML = '';
      rowRefs = {};
      clearInterval(codeTimer);
      document.getElementById('listInfo').textContent = entries.length ? t('listCount', { N: entries.length }) : t('listEmpty');
      entries.forEach(row => {
        const tr = document.createElement('tr');
        tr.dataset.label = row.label;
        tr.innerHTML = `
          <td>
            <div class="tag">${row.label}</div>
            <div class="muted tiny">${(row.algo || 'SHA1').toUpperCase()} · ${(row.digits || 6)} digit · ${(row.period || 30)}s</div>
          </td>
          <td class="code-col"><div class="code-chip" data-code>${t('loading')}</div></td>
          <td>
            <div class="countdown" data-countdown>
              <span class="countdown-ring" data-countdown-ring></span>
              <span class="muted tiny" data-countdown-text>—</span>
            </div>
          </td>
          <td>${row.issuer || '-'}</td>
          <td class="muted">${row.account || '-'}</td>
          <td>
            <div class="actions">
              <button style="padding:6px 10px;" onclick="startEdit('${row.label}')" data-i18n="btnEdit">${t('btnEdit')}</button>
              <button style="padding:6px 10px;" onclick="deleteEntry('${row.label}')" class="danger" data-i18n="btnDelete">${t('btnDelete')}</button>
            </div>
          </td>`;
        rowRefs[row.label] = {
          code: tr.querySelector('[data-code]'),
          countdown: tr.querySelector('[data-countdown-text]'),
          countdownRing: tr.querySelector('[data-countdown-ring]')
        };
        tbody.appendChild(tr);
      });
      codeState = {};
    };
    const updateCountdownVisual = (label, remaining, period) => {
      const ref = rowRefs[label];
      if (!ref) return;
      const safePeriod = period || (codeState[label] && codeState[label].period) || 30;
      const remainVal = Math.max(0, Math.round(remaining || 0));
      if (ref.countdown) {
        const suffix = lang === 'id' ? 'd' : 's';
        ref.countdown.textContent = `${remainVal}${suffix}`;
      }
      if (ref.countdownRing) {
        const ratio = safePeriod ? remainVal / safePeriod : 0;
        const angle = Math.max(0, Math.min(360, Math.round(ratio * 360)));
        ref.countdownRing.style.setProperty('--progress', `${angle}deg`);
        let color = DEFAULT_ACCENT;
        if (ratio <= 0.2) {
          color = DANGER_ACCENT;
        } else if (ratio <= 0.5) {
          color = WARN_ACCENT;
        }
        ref.countdownRing.style.setProperty('--ring-color', color);
      }
    };
    async function loadList() {
      const res = await api('/api/list');
      if (!res.ok) {
        msg(res.data.error || t('loadFail'), true);
        return;
      }
      entriesCache = res.data.entries || [];
      renderList(entriesCache);
      if (entriesCache.length) {
        await refreshCodes();
      } else {
        clearInterval(codeTimer);
        setCodeStatus(t('vaultEmptyLive'));
      }
    }
    async function deleteEntry(label) {
      const sure = confirm(t('deleteAsk', { LABEL: label }));
      if (!sure) return;
      const res = await api('/api/delete', { method: 'POST', body: JSON.stringify({ label }) });
      if (!res.ok) {
        msg(res.data.error || t('deleteFail'), true);
        return;
      }
      msg(t('deleteSuccess', { LABEL: label }));
      resetForm();
      loadList();
    }
    function startEdit(label) {
      const found = entriesCache.find(e => e.label === label);
      if (!found) return;
      editingLabel = label;
      formMode.textContent = t('formModeEdit', { LABEL: label });
      submitBtn.textContent = t('btnUpdate');
      cancelEditBtn.style.display = "inline-block";
      if (formTitleEl) formTitleEl.textContent = t('formTitleEdit');
      document.getElementById('label').value = found.label;
      document.getElementById('issuer').value = found.issuer || '';
      document.getElementById('account').value = found.account || '';
      document.getElementById('secret').value = '';
      document.getElementById('digits').value = found.digits || '';
      document.getElementById('period').value = found.period || '';
      document.getElementById('algo').value = found.algo || '';
      msg(t('editMode', { LABEL: label }));
    }
    async function refreshCodes() {
      if (!Object.keys(rowRefs).length) {
        clearInterval(codeTimer);
        return;
      }
      if (refreshingCodes) return;
      refreshingCodes = true;
      const res = await api('/api/codes');
      refreshingCodes = false;
      if (!res.ok) {
        setCodeStatus(res.data.error || t('codeFail'), true);
        return;
      }
      const codes = res.data.entries || [];
      codeState = {};
      let soonest = 60;
      codes.forEach(item => {
        const ref = rowRefs[item.label];
        if (!ref) return;
        ref.code.textContent = item.code || '-';
        const remain = item.expires_in || item.period || 30;
        const period = item.period || 30;
        codeState[item.label] = { remaining: remain, period };
        updateCountdownVisual(item.label, remain, period);
        soonest = Math.min(soonest, remain);
      });
      if (!codes.length) {
        setCodeStatus(t('noCodes'), true);
        clearInterval(codeTimer);
        return;
      }
      setCodeStatus(t('syncStatus', { TIME: new Date().toLocaleTimeString() }));
      startTicker(soonest || 30);
    }
    function startTicker(nextRefreshIn) {
      clearInterval(codeTimer);
      let wait = nextRefreshIn || 30;
      codeTimer = setInterval(() => {
        if (!Object.keys(codeState).length) return;
        let soonest = Infinity;
        Object.entries(codeState).forEach(([label, state]) => {
          state.remaining = Math.max(0, (state.remaining || state.period || 30) - 1);
          updateCountdownVisual(label, state.remaining, state.period);
          soonest = Math.min(soonest, state.remaining || state.period || 30);
        });
        wait -= 1;
        if (soonest <= 0 || wait <= 0) {
          refreshCodes();
        }
      }, 1000);
    }
    addForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const payload = {
        label: document.getElementById('label').value.trim(),
        issuer: document.getElementById('issuer').value.trim(),
        account: document.getElementById('account').value.trim(),
        secret: document.getElementById('secret').value.trim(),
        digits: document.getElementById('digits').value.trim(),
        period: document.getElementById('period').value.trim(),
        algo: document.getElementById('algo').value.trim(),
      };
      if (!payload.label) {
        msg(t('labelRequired'), true);
        return;
      }
      if (!editingLabel && !payload.secret) {
        msg(t('secretRequired'), true);
        return;
      }
      if (!payload.secret) delete payload.secret;
      if (!payload.digits) delete payload.digits;
      if (!payload.period) delete payload.period;
      if (!payload.algo) delete payload.algo;
      let res;
      if (editingLabel) {
        payload.current_label = editingLabel;
        res = await api('/api/update', { method: 'POST', body: JSON.stringify(payload) });
      } else {
        res = await api('/api/add', { method: 'POST', body: JSON.stringify(payload) });
      }
      if (!res.ok) {
        msg(res.data.error || t('opFail'), true);
        return;
      }
      msg(editingLabel ? t('updateSuccess', { LABEL: payload.label }) : t('addSuccess', { LABEL: payload.label }));
      resetForm();
      await loadList();
    });
    applyThemeMode();
    applyLang();
    loadList();
  </script>
</body>
</html>
"""

HTML = HTML_TEMPLATE.replace("__HOST_LABEL__", DISPLAY_HOST).replace("__LANG__", LANG)


def parse_totp_uri(uri):
    parsed = urllib.parse.urlparse(uri)
    if parsed.scheme.lower() != "otpauth":
        return None
    if parsed.netloc.lower() != "totp":
        return None
    label = urllib.parse.unquote(parsed.path.lstrip("/"))
    issuer = ""
    account = ""
    if ":" in label:
        issuer, account = label.split(":", 1)
    else:
        issuer = label
    params = urllib.parse.parse_qs(parsed.query)
    secret = (params.get("secret") or [""])[0].replace(" ", "").upper()
    if not secret:
        return None
    digits = (params.get("digits") or [None])[0]
    period = (params.get("period") or [None])[0]
    algo = (params.get("algorithm") or params.get("algo") or ["SHA1"])[0].upper()
    issuer_param = (params.get("issuer") or [""])[0]
    if issuer_param:
        issuer = issuer_param
    return {
        "secret": secret,
        "label": label,
        "issuer": issuer,
        "account": account.strip(),
        "digits": int(digits) if digits and digits.isdigit() else None,
        "period": int(period) if period and period.isdigit() else None,
        "algo": algo or "SHA1",
    }


def scan_qr_bytes(image_bytes):
    zbar = shutil.which("zbarimg")
    if not zbar:
        return None, "scanner_missing"

    def run_zbar(path):
        cmd = [zbar, "--quiet", "--raw", path]
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            return None, "scan_failed"
        raw = (proc.stdout or proc.stderr or "").strip()
        if not raw:
            return None, "scan_empty"
        uri = None
        for line in raw.splitlines():
            line = line.strip()
            if line.startswith("otpauth://"):
                uri = line
                break
        if not uri:
            return None, "no_otpauth"
        data = parse_totp_uri(uri)
        if not data:
            return None, "secret_missing"
        return data, None

    img_type = (imghdr.what(None, h=image_bytes) or "").lower()
    suffix = {
        "jpeg": ".jpg",
        "jpg": ".jpg",
        "png": ".png",
        "gif": ".gif",
        "bmp": ".bmp",
        "webp": ".webp",
        "tiff": ".tiff",
    }.get(img_type, ".img")

    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(image_bytes)
        tmp_path = tmp.name

    # Some users upload camera photos with entire screens; normalize + downscale for zbarimg.
    def convert_image(src_path, high_contrast=False):
        converter = shutil.which("convert") or shutil.which("magick")
        if not converter:
            return None
        with tempfile.NamedTemporaryFile(delete=False, suffix=".png") as converted:
            dst_path = converted.name
        try:
            cmd = [
                converter,
                src_path,
                "-auto-orient",
                "-strip",
                "-resize",
                "1400x1400>",
                "-background",
                "white",
                "-alpha",
                "remove",
                "-alpha",
                "off",
            ]
            if high_contrast:
                cmd.extend(["-colorspace", "Gray", "-contrast-stretch", "5%"])
            cmd.append(dst_path)
            proc = subprocess.run(
                cmd,
                capture_output=True,
            )
            if proc.returncode != 0:
                try:
                    os.unlink(dst_path)
                except OSError:
                    pass
                return None
            return dst_path
        except Exception:
            try:
                os.unlink(dst_path)
            except OSError:
                pass
            return None

    try:
        data, err = run_zbar(tmp_path)
        if not err:
            return data, None
        last_err = err
        if err not in ("scan_failed", "scan_empty", "no_otpauth"):
            return None, err
        attempts = [
            convert_image(tmp_path),
            convert_image(tmp_path, high_contrast=True),
        ]
        for converted in [p for p in attempts if p]:
            try:
                data, err = run_zbar(converted)
                if not err:
                    return data, None
                last_err = err
            finally:
                try:
                    os.unlink(converted)
                except OSError:
                    pass
        return None, last_err
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass


def run_sat(args):
    env = os.environ.copy()
    env["SAT_OUTPUT"] = "json"
    proc = subprocess.run([SCRIPT] + args, capture_output=True, text=True, env=env)
    return proc


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def _authorized(self):
        if not TOKEN:
            return True
        header = self.headers.get("X-SAT-Token", "")
        if header == TOKEN:
            return True
        self._send_json(401, {"error": "unauthorized", "message": "Set header X-SAT-Token"})
        return False

    def _send_json(self, status, data):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _serve_html(self):
        body = HTML.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _handle_proc(self, proc, success_code=200):
        if proc.returncode == 0:
            try:
                data = json.loads(proc.stdout or "{}")
            except Exception:
                data = {"stdout": proc.stdout}
            self._send_json(success_code, data)
        else:
            err_msg = (proc.stderr or proc.stdout or "").strip()
            self._send_json(
                400,
                {
                    "error": err_msg or "command_failed",
                    "code": proc.returncode,
                    "stdout": (proc.stdout or "").strip(),
                    "stderr": (proc.stderr or "").strip(),
                },
            )

    def _handle_scan_qr(self, payload):
        image_b64 = (payload.get("image") or "").strip()
        if not image_b64:
            return self._send_json(400, {"error": "image_required"})
        try:
            image_bytes = base64.b64decode(image_b64, validate=True)
        except binascii.Error:
            return self._send_json(400, {"error": "invalid_image"})
        data, err = scan_qr_bytes(image_bytes)
        if err:
            messages = {
                "scanner_missing": "QR scanner (zbarimg) not available. Install 'zbarimg'.",
                "scan_failed": "Failed to scan QR image.",
                "scan_empty": "QR image did not contain data.",
                "no_otpauth": "QR is not an otpauth URL.",
                "secret_missing": "QR code missing secret.",
            }
            return self._send_json(400, {"error": err, "message": messages.get(err, "Scan failed.")})
        self._send_json(
            200,
            {
                "secret": data.get("secret"),
                "label": data.get("label"),
                "issuer": data.get("issuer"),
                "account": data.get("account"),
                "digits": data.get("digits"),
                "period": data.get("period"),
                "algo": data.get("algo"),
            },
        )

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/":
            return self._serve_html()

        if not self._authorized():
            return

        if parsed.path == "/api/list":
            proc = run_sat(["list", "--json"])
            return self._handle_proc(proc)

        if parsed.path == "/api/show":
            qs = urllib.parse.parse_qs(parsed.query)
            label = (qs.get("label") or [""])[0]
            if not label:
                return self._send_json(400, {"error": "label_required"})
            proc = run_sat(["show", label, "--json"])
            return self._handle_proc(proc)

        if parsed.path == "/api/code":
            qs = urllib.parse.parse_qs(parsed.query)
            label = (qs.get("label") or [""])[0]
            if not label:
                return self._send_json(400, {"error": "label_required"})
            proc = run_sat(["code", label, "--json"])
            return self._handle_proc(proc)

        if parsed.path == "/api/codes":
            proc = run_sat(["codes", "--json"])
            return self._handle_proc(proc)

        return self._send_json(404, {"error": "not_found"})

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if not self._authorized():
            return

        length = int(self.headers.get("Content-Length", "0") or 0)
        body = self.rfile.read(length) if length else b"{}"
        try:
            payload = json.loads(body.decode() or "{}")
        except Exception:
            payload = {}

        if parsed.path == "/api/scan_qr":
            return self._handle_scan_qr(payload)

        if parsed.path == "/api/add":
            label = (payload.get("label") or "").strip()
            secret = (payload.get("secret") or "").strip()
            if not label or not secret:
                return self._send_json(400, {"error": "label_and_secret_required"})
            digits = payload.get("digits")
            period = payload.get("period")
            args = [
                "add",
                "--label",
                label,
                "--issuer",
                payload.get("issuer", ""),
                "--account",
                payload.get("account", ""),
                "--secret",
                secret,
                "--digits",
                str(digits if digits not in (None, "") else 6),
                "--period",
                str(period if period not in (None, "") else 30),
                "--algo",
                payload.get("algo", "SHA1"),
                "--json",
            ]
            proc = run_sat(args)
            return self._handle_proc(proc, success_code=201)

        if parsed.path == "/api/update":
            current_label = (payload.get("current_label") or "").strip()
            if not current_label:
                return self._send_json(400, {"error": "label_required"})

            target_label = (payload.get("new_label") or payload.get("label") or "").strip()

            args = ["update", current_label, "--json"]
            if target_label and target_label != current_label:
                args += ["--new-label", target_label]

            if "issuer" in payload:
                args += ["--issuer", str(payload.get("issuer") or "")]
            if "account" in payload:
                args += ["--account", str(payload.get("account") or "")]

            secret = (payload.get("secret") or "").strip()
            if secret:
                args += ["--secret", secret]

            digits = str(payload.get("digits") or "").strip()
            if digits:
                args += ["--digits", digits]

            period = str(payload.get("period") or "").strip()
            if period:
                args += ["--period", period]

            algo = (payload.get("algo") or "").strip()
            if algo:
                args += ["--algo", algo]

            proc = run_sat(args)
            return self._handle_proc(proc)

        if parsed.path == "/api/delete":
            label = (payload.get("label") or "").strip()
            if not label:
                return self._send_json(400, {"error": "label_required"})
            proc = run_sat(["delete", label, "--json", "--yes"])
            return self._handle_proc(proc)

        return self._send_json(404, {"error": "not_found"})


with http.server.ThreadingHTTPServer((HOST, PORT), Handler) as server:
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
PY
}

web_running_pid() {
	local pid=""

	[[ -f "$WEB_PID_FILE" ]] || return 1
	read -r pid < "$WEB_PID_FILE" || true
	if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
		printf "%s" "$pid"
		return 0
	fi

	rm -f "$WEB_PID_FILE"
	return 1
}

validate_master_pass() {
	if ! openssl enc -aes-256-cbc -pbkdf2 -d -salt \
		-in "$VAULT_FILE" -out /dev/null \
		-pass env:MASTER_PASS 2>/dev/null; then
		die "Gagal decrypt vault. Password salah atau file korup."
	fi
}

cmd_web_start() {
	check_deps
	require_cmd python3
	ensure_vault_dir

	if [[ ! -f "$VAULT_FILE" ]]; then
		die "Vault tidak ditemukan di '$VAULT_FILE'. Jalankan init dulu."
	fi

	local pid=""
	if pid="$(web_running_pid)"; then
		echo "SAT Web UI sudah berjalan (PID $pid)."
		echo "Log: $WEB_LOG_FILE"
		return
	fi

	read_master_pass
	export MASTER_PASS SAT_LANG SAT_WEB_TOKEN
	validate_master_pass

	local script_path
	script_path="$(realpath "$0" 2>/dev/null || readlink -f "$0" 2>/dev/null || printf "%s" "$0")"

	if command -v setsid >/dev/null 2>&1; then
		setsid "$script_path" web "$@" > "$WEB_LOG_FILE" 2>&1 < /dev/null &
	else
		nohup "$script_path" web "$@" > "$WEB_LOG_FILE" 2>&1 < /dev/null &
	fi
	pid=$!
	printf "%s\n" "$pid" > "$WEB_PID_FILE"

	sleep 1
	if ! kill -0 "$pid" 2>/dev/null; then
		rm -f "$WEB_PID_FILE"
		echo "SAT Web UI gagal start. Cek log: $WEB_LOG_FILE" >&2
		tail -n 20 "$WEB_LOG_FILE" >&2 || true
		return 1
	fi

	echo "SAT Web UI berjalan di background (PID $pid)."
	echo "Log: $WEB_LOG_FILE"
}

cmd_web_stop() {
	ensure_vault_dir

	local pid=""
	if ! pid="$(web_running_pid)"; then
		echo "SAT Web UI background tidak berjalan."
		return
	fi

	pkill -TERM -P "$pid" 2>/dev/null || true
	kill "$pid" 2>/dev/null || true
	rm -f "$WEB_PID_FILE"
	echo "SAT Web UI background dihentikan."
}

cmd_web_status() {
	ensure_vault_dir

	local pid=""
	if pid="$(web_running_pid)"; then
		echo "SAT Web UI background berjalan (PID $pid)."
		echo "Log: $WEB_LOG_FILE"
		return
	fi

	echo "SAT Web UI background tidak berjalan."
}

# -------------------------------------------------------------------
# Interactive Menu
# -------------------------------------------------------------------

interactive_menu() {
	while true; do
		clear
		print_banner
		print_status

		cat <<EOF
  1) $(t_cli menu_1)
  2) $(t_cli menu_2)
  3) $(t_cli menu_3)
  4) $(t_cli menu_4)
  5) $(t_cli menu_5)
  6) $(t_cli menu_6)
  7) $(t_cli menu_7)
  8) $(t_cli menu_8)
  9) $(t_cli menu_9)
 10) $(t_cli menu_10)
  0) $(t_cli menu_0)

EOF

		printf "%s" "$(t_cli prompt_choice)"
		read -r choice

		case "$choice" in
			1)
				run_action cmd_list
				;;
			2)
				printf "%s" "$(t_cli prompt_label_example)"
				read -r lbl
				if [[ -n "$lbl" ]]; then
					run_action cmd_add "$lbl"
				else
					echo "$(t_cli warn_label_empty)"
				fi
				;;
			3)
				printf "%s" "$(t_cli prompt_label_view)"
				read -r lbl
				if [[ -n "$lbl" ]]; then
					run_action cmd_show "$lbl"
				else
					echo "$(t_cli warn_label_empty)"
				fi
				;;
			4)
				printf "%s" "$(t_cli prompt_label_code)"
				read -r lbl
				if [[ -n "$lbl" ]]; then
					run_action cmd_code "$lbl"
				else
					echo "$(t_cli warn_label_empty)"
				fi
				;;
			5)
				printf "%s" "$(t_cli prompt_label_live)"
				read -r lbl
				if [[ -n "$lbl" ]]; then
					run_action cmd_code "$lbl" --live
				else
					echo "$(t_cli warn_label_empty)"
				fi
				;;
			6)
				printf "%s" "$(t_cli prompt_label_delete)"
				read -r lbl
				if [[ -n "$lbl" ]]; then
					run_action cmd_delete "$lbl"
				else
					echo "$(t_cli warn_label_empty)"
				fi
				;;
			7)
				local default_host
				default_host="$(detect_default_host)"
				echo "$(t_cli web_info_1)"
				echo "$(t_cli web_info_2)"
				printf "$(t_cli web_prompt_host)" "$default_host"
				read -r host_choice || true
				host_choice="${host_choice:-$default_host}"
				printf "%s" "$(t_cli web_prompt_port)"
				read -r port_choice || true
				port_choice="${port_choice:-8787}"
				printf "%s" "$(t_cli web_prompt_token)"
				read -r token_choice || true
				args=(--host "$host_choice" --port "$port_choice")
				if [[ -n "$token_choice" ]]; then
					args+=(--token "$token_choice")
				fi
				run_action cmd_web "${args[@]}"
				;;
			8)
				printf "%s" "$(t_cli bundle_prompt_name)"
				read -r name
				if [[ -n "$name" ]]; then
					run_action cmd_portable "$name"
				else
					run_action cmd_portable
				fi
				;;
			9)
				cmd_help
				;;
			10)
				printf "$(t_cli lang_prompt)" "$SAT_LANG"
				read -r new_lang || true
				case "${new_lang,,}" in
					id|en)
						SAT_LANG="${new_lang,,}"
						export SAT_LANG
						printf "$(t_cli lang_set)\n" "$SAT_LANG"
						;;
					"")
						printf "$(t_cli lang_keep)\n" "$SAT_LANG"
						;;
					*)
						echo "$(t_cli lang_invalid)"
						;;
				esac
				;;
			0)
				echo
				echo "$(t_cli bye)"
				break
				;;
			*)
				printf "$(t_cli choice_invalid)\n" "$choice"
				;;
		esac

		echo
		printf "%s" "$(t_cli press_enter)"
		read -r _
	done
}

# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------

main() {
	local cmd="${1-}"

	# Tanpa argumen → langsung menu interaktif
	if [[ -z "$cmd" ]]; then
		interactive_menu
		return
	fi

	case "$cmd" in
		help | -h | --help)
			cmd_help
			;;
		menu)
			interactive_menu
			;;
		init)
			shift || true
			cmd_init "$@"
			;;
		add)
			shift || true
			cmd_add "$@"
			;;
		update | edit)
			shift || true
			cmd_update "$@"
			;;
		list)
			shift || true
			cmd_list "$@"
			;;
		show)
			shift || true
			cmd_show "$@"
			;;
		code)
			shift || true
			cmd_code "$@"
			;;
		codes)
			shift || true
			cmd_codes "$@"
			;;
		delete | del | rm)
			shift || true
			cmd_delete "$@"
			;;
		portable | export)
			shift || true
			cmd_portable "$@"
			;;
		web)
			shift || true
			cmd_web "$@"
			;;
		web-start)
			shift || true
			cmd_web_start "$@"
			;;
		web-stop)
			cmd_web_stop
			;;
		web-status)
			cmd_web_status
			;;
		*)
			echo "❌ Unknown command: $cmd"
			echo
			cmd_help
			exit 1
			;;
	esac
}

main "$@"
