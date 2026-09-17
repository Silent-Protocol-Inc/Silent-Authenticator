#!/usr/bin/env bash

set -euo pipefail

SAT_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SAT_EXPECTED_VERSION="$(<"$SAT_PROJECT_ROOT/VERSION")"
SAT_TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sat-test.XXXXXX")"
SAT_TEST_HOME="$SAT_TEST_ROOT/home"
SAT_TEST_TMP="$SAT_TEST_ROOT/tmp"
SAT_TEST_PASS='integration-password-only'
SAT_TEST_SECRET='JBSWY3DPEHPK3PXP'
SAT_SERVER_PID=''
SAT_PORT_HOLDER_PID=''

stop_test_server() {
	local child_pid
	[[ -n "$SAT_SERVER_PID" ]] || return
	while IFS= read -r child_pid; do
		child_pid="${child_pid//[[:space:]]/}"
		if [[ "$child_pid" =~ ^[0-9]+$ ]]; then kill "$child_pid" 2>/dev/null || true; fi
	done < <(ps -o pid= --ppid "$SAT_SERVER_PID" 2>/dev/null)
	kill "$SAT_SERVER_PID" 2>/dev/null || true
	wait "$SAT_SERVER_PID" 2>/dev/null || true
	SAT_SERVER_PID=''
}

cleanup() {
	stop_test_server
	if [[ -n "$SAT_PORT_HOLDER_PID" ]]; then kill "$SAT_PORT_HOLDER_PID" 2>/dev/null || true; fi
	rm -rf -- "$SAT_TEST_ROOT"
}
trap cleanup EXIT

fail_test() {
	printf 'FAIL: %s\n' "$1" >&2
	exit 1
}

wait_for_http() {
	local url="$1" description="$2" attempt
	for ((attempt = 0; attempt < 75; attempt++)); do
		curl -fsS "$url" >/dev/null 2>&1 && return
		sleep 0.2
	done
	if [[ -f "$SAT_TEST_ROOT/web.log" ]]; then sed -n '1,40p' "$SAT_TEST_ROOT/web.log" >&2; fi
	fail_test "$description did not become ready"
}

sat() {
	SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" "$@" 3<<<"$SAT_TEST_PASS"
}

json_add() {
	local payload="$1"
	printf '%s' "$payload" | SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" add --payload-stdin --json 3<<<"$SAT_TEST_PASS"
}

json_update() {
	local payload="$1"
	printf '%s' "$payload" | SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" update --payload-stdin --json 3<<<"$SAT_TEST_PASS"
}

mkdir -p "$SAT_TEST_HOME" "$SAT_TEST_TMP"
export TMPDIR="$SAT_TEST_TMP"

concurrent_home="$SAT_TEST_ROOT/concurrent-home"
mkdir -p "$concurrent_home"
set +e
SAT_HOME="$concurrent_home" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" init --json 3<<<"$SAT_TEST_PASS" >"$SAT_TEST_ROOT/init-one.json" 2>/dev/null &
init_one_pid=$!
SAT_HOME="$concurrent_home" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" init --json 3<<<"$SAT_TEST_PASS" >"$SAT_TEST_ROOT/init-two.json" 2>/dev/null &
init_two_pid=$!
wait "$init_one_pid"; init_one_status=$?
wait "$init_two_pid"; init_two_status=$?
set -e
sorted_init_statuses="$(printf '%s\n%s\n' "$init_one_status" "$init_two_status" | sort -n | paste -sd, -)"
[[ "$sorted_init_statuses" == '0,5' ]] || fail_test "concurrent init statuses must be 0 and 5, got $sorted_init_statuses"
for index in 1 2 3 4 5 6 7 8 9 10; do
	payload="$(jq -cn --arg lbl "parallel-$index" --arg secret "$SAT_TEST_SECRET" '{label:$lbl,secret:$secret}')"
	printf '%s' "$payload" | SAT_HOME="$concurrent_home" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" add --payload-stdin --json 3<<<"$SAT_TEST_PASS" >/dev/null &
done
wait
parallel_count="$(SAT_HOME="$concurrent_home" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" list --json 3<<<"$SAT_TEST_PASS" | jq '.entries | length')"
[[ "$parallel_count" -eq 10 ]] || fail_test "concurrent writes returned $parallel_count entries"

sat init --json | jq -e '.status == "created"' >/dev/null
[[ "$(sat version)" == "SAT - Silent Authenticator Tool $SAT_EXPECTED_VERSION" ]] || fail_test 'CLI version must match VERSION'
json_add '{"label":"github-main","issuer":"GitHub","account":"tester@example.invalid","secret":"JBSWY3DPEHPK3PXP","digits":6,"period":30,"algo":"SHA1"}' | jq -e '.status == "created"' >/dev/null

set +e
json_add '{"label":"github-main","issuer":"Duplicate","account":"x","secret":"JBSWY3DPEHPK3PXP"}' >/dev/null 2>&1
duplicate_status=$?
set -e
[[ "$duplicate_status" -eq 5 ]] || fail_test 'duplicate label must exit 5'

malicious_label='<img src=x onerror=alert(1)>'
json_add "$(jq -cn --arg lbl "$malicious_label" --arg secret "$SAT_TEST_SECRET" '{label:$lbl,issuer:"XSS",account:"literal",secret:$secret}')" >/dev/null
sat list --json | jq -e --arg lbl "$malicious_label" '.entries | any(.label == $lbl)' >/dev/null

code="$(sat code github-main --json | jq -r '.code')"
[[ "$code" =~ ^[0-9]{6}$ ]] || fail_test 'TOTP code must contain six digits'

json_update '{"current_label":"github-main","new_label":"github-primary","issuer":"GitHub Inc","digits":8}' | jq -e '.status == "updated" and .label == "github-primary"' >/dev/null
sat search primary --json | jq -e '.entries | length == 1' >/dev/null
sat show github-primary --json | jq -e '.digits == 8 and .issuer == "GitHub Inc" and (has("secret") | not)' >/dev/null

set +e
SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" list --json 3<<<'wrong-password' >/dev/null 2>&1
wrong_password_status=$?
set -e
[[ "$wrong_password_status" -eq 3 ]] || fail_test 'wrong password must exit 3'

(
	cd "$SAT_TEST_ROOT"
	sat backup integration --json | jq -e '.vault_deleted == false' >/dev/null
)
[[ -f "$SAT_TEST_ROOT/integration.zip" ]] || fail_test 'backup archive missing'
unzip -tq "$SAT_TEST_ROOT/integration.zip" >/dev/null

sat delete github-primary --yes --json | jq -e '.status == "deleted"' >/dev/null
sat restore "$SAT_TEST_ROOT/integration.zip" --yes --json | jq -e '.status == "restored"' >/dev/null
sat show github-primary --json >/dev/null

(
	cd "$SAT_TEST_ROOT"
	sat move integration-move --yes --json | jq -e '.status == "moved" and .vault_deleted == true' >/dev/null
)
[[ ! -f "$SAT_TEST_HOME/otp.vault" ]] || fail_test 'move must delete the local test vault'
sat restore "$SAT_TEST_ROOT/integration-move.zip" --yes --json >/dev/null

python3 - "$SAT_TEST_ROOT/integration-move.zip" "$SAT_TEST_ROOT/unsafe.zip" <<'PY'
import sys
import zipfile

source, target = sys.argv[1:3]
with zipfile.ZipFile(source) as original:
    vault_name = next(name for name in original.namelist() if name.endswith("/otp.vault"))
    vault = original.read(vault_name)
with zipfile.ZipFile(target, "w") as unsafe:
    unsafe.writestr("../outside.txt", b"unsafe")
    unsafe.writestr("unsafe/otp.vault", vault)
PY
set +e
sat restore "$SAT_TEST_ROOT/unsafe.zip" --yes --json >/dev/null 2>&1
unsafe_archive_status=$?
set -e
[[ "$unsafe_archive_status" -eq 6 ]] || fail_test 'unsafe archive path must exit 6'
[[ ! -e "$SAT_TEST_ROOT/outside.txt" ]] || fail_test 'unsafe archive escaped its destination'

test_port="$((20000 + ($$ % 20000)))"

SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" web --host 127.0.0.1 --port "$test_port" 3<<<"$SAT_TEST_PASS" >"$SAT_TEST_ROOT/web.log" 2>&1 &
SAT_SERVER_PID=$!
wait_for_http "http://127.0.0.1:$test_port/health" 'foreground web server'

curl -fsS "http://127.0.0.1:$test_port/api/list" | jq -e '.entries | length == 2' >/dev/null
headers="$(curl -fsSI "http://127.0.0.1:$test_port/")"
grep -Fq "Content-Security-Policy: default-src 'none'" <<<"$headers" || fail_test 'default-deny CSP missing'
grep -Fiq 'Cache-Control: no-store' <<<"$headers" || fail_test 'no-store header missing'

origin_status="$(curl -sS -o /dev/null -w '%{http_code}' -H 'Origin: https://evil.invalid' -H 'Content-Type: application/json' -d '{"label":"x"}' "http://127.0.0.1:$test_port/api/delete")"
[[ "$origin_status" == '403' ]] || fail_test 'cross-origin mutation must be rejected'
large_status="$(python3 - <<'PY' | curl -sS -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' --data-binary @- "http://127.0.0.1:$test_port/api/add"
print('{"padding":"' + ('x' * 1_500_001) + '"}')
PY
)"
[[ "$large_status" == '413' ]] || fail_test 'oversized request must be rejected'

process_args="$(ps -o args= -p "$SAT_SERVER_PID")"
[[ "$process_args" != *"$SAT_TEST_PASS"* && "$process_args" != *"$SAT_TEST_SECRET"* ]] || fail_test 'secret found in server argv'
if [[ -r "/proc/$SAT_SERVER_PID/environ" ]]; then
	! tr '\0' '\n' <"/proc/$SAT_SERVER_PID/environ" | grep -Fq "$SAT_TEST_PASS" || fail_test 'password found in server environment'
fi

stop_test_server

token_port="$((test_port + 1))"
test_token='integration-web-token'
SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 SAT_WEB_TOKEN_FD=4 "$SAT_PROJECT_ROOT/sat.sh" web --host 127.0.0.1 --port "$token_port" \
	3<<<"$SAT_TEST_PASS" 4<<<"$test_token" >"$SAT_TEST_ROOT/web-token.log" 2>&1 &
SAT_SERVER_PID=$!
wait_for_http "http://127.0.0.1:$token_port/health" 'token-protected web server'
unauthorized_status="$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:$token_port/api/list")"
[[ "$unauthorized_status" == '401' ]] || fail_test 'protected API must reject a missing token'
curl -fsS -H "X-SAT-Token: $test_token" "http://127.0.0.1:$token_port/api/list" >/dev/null
process_args="$(ps -o args= -p "$SAT_SERVER_PID")"
[[ "$process_args" != *"$test_token"* ]] || fail_test 'web token found in server argv'
if [[ -r "/proc/$SAT_SERVER_PID/environ" ]]; then
	! tr '\0' '\n' <"/proc/$SAT_SERVER_PID/environ" | grep -Fq "$test_token" || fail_test 'web token found in server environment'
fi
stop_test_server

lifecycle_port="$((test_port + 2))"
SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" web-start --host 127.0.0.1 --port "$lifecycle_port" 3<<<"$SAT_TEST_PASS" >/dev/null
SAT_HOME="$SAT_TEST_HOME" "$SAT_PROJECT_ROOT/sat.sh" web-status | grep -Fq "http://127.0.0.1:$lifecycle_port"
[[ "$(stat -c '%a' "$SAT_TEST_HOME/sat-web.state")" == '600' ]] || fail_test 'web state must use mode 600'
curl -fsS "http://127.0.0.1:$lifecycle_port/health" >/dev/null
SAT_HOME="$SAT_TEST_HOME" "$SAT_PROJECT_ROOT/sat.sh" web-stop >/dev/null
[[ ! -e "$SAT_TEST_HOME/sat-web.state" ]] || fail_test 'web-stop must remove web state'
set +e
SAT_HOME="$SAT_TEST_HOME" "$SAT_PROJECT_ROOT/sat.sh" web-status >/dev/null
lifecycle_status=$?
set -e
[[ "$lifecycle_status" -eq 1 ]] || fail_test 'web-status must report stopped lifecycle'

conflict_port="$((test_port + 3))"
python3 -m http.server "$conflict_port" --bind 127.0.0.1 >"$SAT_TEST_ROOT/port-holder.log" 2>&1 &
SAT_PORT_HOLDER_PID=$!
wait_for_http "http://127.0.0.1:$conflict_port/" 'port-conflict fixture'
set +e
SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" web-start --host 127.0.0.1 --port "$conflict_port" 3<<<"$SAT_TEST_PASS" >/dev/null 2>&1
conflict_status=$?
set -e
[[ "$conflict_status" -eq 8 ]] || fail_test 'web-start on an occupied port must exit 8'
[[ ! -e "$SAT_TEST_HOME/sat-web.pid" && ! -e "$SAT_TEST_HOME/sat-web.state" ]] || fail_test 'failed web-start must clean lifecycle files'
kill "$SAT_PORT_HOLDER_PID"
wait "$SAT_PORT_HOLDER_PID" 2>/dev/null || true
SAT_PORT_HOLDER_PID=''

set +e
SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" web --host 0.0.0.0 --port "$test_port" 3<<<"$SAT_TEST_PASS" >/dev/null 2>&1
network_status=$?
set -e
[[ "$network_status" -eq 6 ]] || fail_test 'network bind without token must exit 6'

public_port="$((test_port + 4))"
SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 SAT_WEB_TOKEN_FD=4 SAT_WEB_DISPLAY_HOST=5.104.81.199 \
	"$SAT_PROJECT_ROOT/sat.sh" web-public --port "$public_port" 3<<<"$SAT_TEST_PASS" 4<<<"$test_token" >/dev/null
SAT_HOME="$SAT_TEST_HOME" "$SAT_PROJECT_ROOT/sat.sh" web-status | grep -Fq "http://5.104.81.199:$public_port"
public_unauthorized_status="$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:$public_port/api/list")"
[[ "$public_unauthorized_status" == '401' ]] || fail_test 'public web mode must require a token'
curl -fsS -H "X-SAT-Token: $test_token" "http://127.0.0.1:$public_port/api/list" >/dev/null
SAT_HOME="$SAT_TEST_HOME" "$SAT_PROJECT_ROOT/sat.sh" web-stop >/dev/null

domain_port="$((test_port + 5))"
domain_parse="$(SAT_ROOT="$SAT_PROJECT_ROOT" SAT_HOME="$SAT_TEST_HOME" SAT_WEB_TOKEN_FD=4 bash -c '
	source "$SAT_ROOT/lib/common.sh"
	source "$SAT_ROOT/lib/commands.sh"
	parse_web_options --domain sat.example.com --cloudflare dns-only --port "'$domain_port'"
	printf "%s|%s|%s|%s" "$WEB_HOST" "$WEB_PORT" "$WEB_DEPLOYMENT" "$WEB_CLOUDFLARE"
' 4<<<"$test_token")"
[[ "$domain_parse" == "127.0.0.1|$domain_port|domain|dns-only" ]] || fail_test 'HTTPS domain mode must bind SAT to localhost with the chosen origin port'
domain_vhost="$(SAT_ROOT="$SAT_PROJECT_ROOT" SAT_HOME="$SAT_TEST_HOME" bash -c '
	source "$SAT_ROOT/lib/common.sh"
	source "$SAT_ROOT/lib/commands.sh"
	web_domain_render_vhost sat.example.com "'$domain_port'" yes
')"
grep -Fq "proxy_pass http://127.0.0.1:$domain_port;" <<<"$domain_vhost" || fail_test 'HTTPS domain vhost must proxy to the localhost origin port'
grep -Fq 'ssl_certificate /etc/letsencrypt/live/sat.example.com/fullchain.pem;' <<<"$domain_vhost" || fail_test 'HTTPS domain vhost must use the Certbot certificate'
grep -Fq 'sat-cloudflare-realip.conf' <<<"$domain_vhost" || fail_test 'proxied HTTPS domain vhost must restore the Cloudflare client IP'

domain_vhost_servers="$(printf '%s\n' "$domain_vhost" | grep -c 'server_name ')"
[[ "$domain_vhost_servers" -eq 2 ]] || fail_test "vhost must declare exactly two server blocks, got $domain_vhost_servers"
[[ "$(printf '%s\n' "$domain_vhost" | grep -o 'server_name [^;]*;' | sort -u)" == 'server_name sat.example.com;' ]] || fail_test 'vhost must declare exactly one hostname'
! grep -Fq 'spm' <<<"$domain_vhost" || fail_test 'vhost must not include a hostname from another website'
grep -Fq '# SAT owner:' <<<"$domain_vhost" || fail_test 'vhost must carry the SAT owner marker'
! grep -Eq 'listen .*default_server|server_name[[:space:]]+_|server_name[[:space:]]+\*\.|server_name[[:space:]]+\.' <<<"$domain_vhost" || fail_test 'SAT domain vhost must not become a wildcard or default server'

replacement_vhost="$(SAT_ROOT="$SAT_PROJECT_ROOT" SAT_HOME="$SAT_TEST_HOME" bash -c '
	source "$SAT_ROOT/lib/common.sh"
	source "$SAT_ROOT/lib/commands.sh"
	web_domain_render_vhost replacement.example.com "'$domain_port'" no
')"
grep -Fq 'server_name replacement.example.com;' <<<"$replacement_vhost" || fail_test 'replacement hostname must be rendered exactly'
! grep -Fq 'sat.example.com' <<<"$replacement_vhost" || fail_test 'previous hostname must never become an implicit SAT alias'

owner_a="$(SAT_ROOT="$SAT_PROJECT_ROOT" SAT_HOME="$SAT_TEST_HOME/owner-a" bash -c '
	source "$SAT_ROOT/lib/common.sh"
	source "$SAT_ROOT/lib/commands.sh"
	web_domain_owner_id
')"
owner_b="$(SAT_ROOT="$SAT_PROJECT_ROOT" SAT_HOME="$SAT_TEST_HOME/owner-b" bash -c '
	source "$SAT_ROOT/lib/common.sh"
	source "$SAT_ROOT/lib/commands.sh"
	web_domain_owner_id
')"
[[ -n "$owner_a" && "$owner_a" != "$owner_b" ]] || fail_test 'distinct SAT homes must produce distinct domain owners'

owner_guard="$(SAT_ROOT="$SAT_PROJECT_ROOT" SAT_HOME="$SAT_TEST_HOME/owner-a" bash -c '
	source "$SAT_ROOT/lib/common.sh"
	source "$SAT_ROOT/lib/commands.sh"
	vhost="$(web_domain_render_vhost sat.example.com "'$domain_port'" yes)"
	vhost_owner="$(web_domain_owner_id_from_vhost "$vhost")"
	web_domain_vhost_owner_ok "$vhost" "$vhost_owner" && echo same-owner=ok || echo same-owner=conflict
	web_domain_vhost_owner_ok "$vhost" "'"$owner_b"'" && echo foreign-owner=ok || echo foreign-owner=conflict
')"
grep -Fq 'same-owner=ok' <<<"$owner_guard" || fail_test 'rebinding a hostname owned by the same SAT instance must stay idempotent'
grep -Fq 'foreign-owner=conflict' <<<"$owner_guard" || fail_test "a hostname owned by another SAT instance must not be reused"

normalized_domain="$(SAT_ROOT="$SAT_PROJECT_ROOT" SAT_HOME="$SAT_TEST_HOME" SAT_WEB_TOKEN_FD=4 bash -c '
	source "$SAT_ROOT/lib/common.sh"
	source "$SAT_ROOT/lib/commands.sh"
	parse_web_options --domain SAT.EXAMPLE.COM --cloudflare dns-only --port "'$domain_port'"
	printf "%s" "$WEB_DOMAIN"
' 4<<<"$test_token")"
[[ "$normalized_domain" == 'sat.example.com' ]] || fail_test 'domain input must be normalized to lowercase'

set +e
invalid_domain_error="$(SAT_HOME="$SAT_TEST_HOME" SAT_OUTPUT=json SAT_MASTER_PASS_FD=3 SAT_WEB_TOKEN_FD=4 \
	"$SAT_PROJECT_ROOT/sat.sh" web-domain invalid_domain --cloudflare off --port "$domain_port" \
	3<<<"$SAT_TEST_PASS" 4<<<"$test_token" 2>&1)"
invalid_domain_status=$?
SAT_HOME="$SAT_TEST_HOME" SAT_MASTER_PASS_FD=3 SAT_WEB_TOKEN_FD=4 \
	"$SAT_PROJECT_ROOT/sat.sh" web-domain sat.example.com --cloudflare maybe --port "$domain_port" \
	3<<<"$SAT_TEST_PASS" 4<<<"$test_token" >/dev/null 2>&1
invalid_cloudflare_status=$?
invalid_cloudflare_dns_error="$(SAT_HOME="$SAT_TEST_HOME" SAT_OUTPUT=json SAT_MASTER_PASS_FD=3 SAT_WEB_TOKEN_FD=4 \
	"$SAT_PROJECT_ROOT/sat.sh" web-domain sat.example.com --cloudflare off --port "$domain_port" \
	3<<<"$SAT_TEST_PASS" 4<<<"$test_token" 2>&1)"
invalid_cloudflare_dns_status=$?
set -e
[[ "$invalid_domain_status" -eq 6 ]] || fail_test 'invalid domain must exit 6'
jq -e '.error == "invalid_domain"' <<<"$invalid_domain_error" >/dev/null || fail_test 'invalid domain must return its stable machine code'
[[ "$invalid_cloudflare_status" -eq 6 ]] || fail_test 'invalid Cloudflare mode must exit 6'
[[ "$invalid_cloudflare_dns_status" -eq 6 ]] || fail_test 'HTTPS domain must require Cloudflare DNS for TXT validation'
jq -e '.error == "cloudflare_dns_required"' <<<"$invalid_cloudflare_dns_error" >/dev/null || fail_test 'HTTPS domain must return the Cloudflare DNS machine code'

menu_output="$(printf '5\n0\n0\n' | SAT_HOME="$SAT_TEST_HOME" "$SAT_PROJECT_ROOT/sat.sh" menu)"
grep -Fq 'Silent Authenticator Tool (SAT)' <<<"$menu_output" || fail_test 'interactive menu must render the SAT ASCII banner'
grep -Fq "v$SAT_EXPECTED_VERSION  © 2026 SilentProtocol. Licensed under Apache-2.0." <<<"$menu_output" || fail_test 'interactive menu must render the release version, copyright year, and license'
grep -Fq $'1) Daftar entri OTP\n2) Tambah OTP\n3) Hasilkan kode OTP' <<<"$menu_output" || fail_test 'interactive CLI menu must render vertically in Indonesian'
grep -Fq '7) Bahasa' <<<"$menu_output" || fail_test 'interactive CLI menu must provide language settings'
grep -Fq 'Global VPS / IP' <<<"$menu_output" || fail_test 'website submenu must include global VPS/IP mode'
grep -Fq 'Domain / subdomain dengan HTTPS' <<<"$menu_output" || fail_test 'website submenu must include HTTPS domain mode'

set +e
indonesian_domain_menu_output="$(printf '5\n2\nsat.example.com\ninvalid\nn\n' | SAT_HOME="$SAT_TEST_HOME" "$SAT_PROJECT_ROOT/sat.sh" menu 2>&1)"
indonesian_domain_menu_status=$?
set -e
[[ "$indonesian_domain_menu_status" -eq 0 ]] || fail_test 'Indonesian domain menu must return safely after incomplete input'
grep -Fq 'Alamat Web UI' <<<"$indonesian_domain_menu_output" || fail_test 'Indonesian domain menu must group address prompts'
grep -Fq 'Port [8787]:' <<<"$indonesian_domain_menu_output" || fail_test 'Indonesian domain menu must prompt for port before DNS mode'
grep -Fq 'Port harus antara 1024 dan 65535.' <<<"$indonesian_domain_menu_output" || fail_test 'Indonesian domain menu must retry an invalid port without changing configuration'

english_menu_output="$(printf '0\n' | SAT_HOME="$SAT_TEST_HOME" SAT_LANG=en "$SAT_PROJECT_ROOT/sat.sh" menu)"
grep -Fq $'1) List OTP entries\n2) Add OTP entry\n3) Generate OTP code' <<<"$english_menu_output" || fail_test 'interactive CLI menu must render vertically in English'
grep -Fq '7) Language' <<<"$english_menu_output" || fail_test 'English interactive CLI menu must provide language settings'

set +e
english_domain_menu_output="$(printf '5\n2\nsat.example.com\ninvalid\nn\n' | SAT_HOME="$SAT_TEST_HOME" SAT_LANG=en "$SAT_PROJECT_ROOT/sat.sh" menu 2>&1)"
english_domain_menu_status=$?
set -e
[[ "$english_domain_menu_status" -eq 0 ]] || fail_test 'English domain menu must return safely after incomplete input'
grep -Fq 'Web UI Address' <<<"$english_domain_menu_output" || fail_test 'English domain menu must group address prompts'
grep -Fq 'Port [8787]:' <<<"$english_domain_menu_output" || fail_test 'English domain menu must prompt for port before DNS mode'
grep -Fq 'Port must be between 1024 and 65535.' <<<"$english_domain_menu_output" || fail_test 'English domain menu must retry an invalid port without changing configuration'

language_persistence_output="$(SAT_ROOT="$SAT_PROJECT_ROOT" SAT_HOME="$SAT_TEST_HOME/language" SAT_LANG=id bash -c '
	source "$SAT_ROOT/lib/common.sh"
	source "$SAT_ROOT/lib/ui.sh"
	SAT_LANG=en; save_language
	SAT_LANG=id; SAT_LANG_EXPLICIT=no; load_saved_language
	printf "%s" "$SAT_LANG"
')"
[[ "$language_persistence_output" == en ]] || fail_test 'saved terminal language must be restored safely'

oversized_secret="$(python3 -c 'print("A" * 1025)')"
set +e
json_add "$(jq -cn --arg secret "$oversized_secret" '{label:"too-large",secret:$secret}')" >/dev/null 2>&1
oversized_secret_status=$?
set -e
[[ "$oversized_secret_status" -eq 6 ]] || fail_test 'oversized secret must exit 6'

find "$SAT_TEST_HOME" -maxdepth 1 -type f \( -name '*.new.*' -o -name '*.restore.*' \) -print -quit | grep -q . && fail_test 'atomic-write temporary file leaked'
find "$SAT_TEST_TMP" -mindepth 1 -print -quit | grep -q . && fail_test 'process temporary file leaked'

! grep -R -n -E 'innerHTML|insertAdjacentHTML|document\.write' "$SAT_PROJECT_ROOT/web/static" >/dev/null || fail_test 'unsafe HTML rendering primitive found'
! grep -R -n -E 'token.*localStorage|localStorage.*token|[?&]token=' "$SAT_PROJECT_ROOT/web/static" >/dev/null || fail_test 'persistent or URL token handling found'

printf 'Integration checks passed.\n'
