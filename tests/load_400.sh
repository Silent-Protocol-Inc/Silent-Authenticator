#!/usr/bin/env bash

set -euo pipefail

SAT_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SAT_LOAD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/sat-load.XXXXXX")"
SAT_LOAD_HOME="$SAT_LOAD_ROOT/home"
SAT_LOAD_TMP="$SAT_LOAD_ROOT/tmp"
SAT_LOAD_PASS='load-test-password-only'
trap 'rm -rf -- "$SAT_LOAD_ROOT"' EXIT
mkdir -p "$SAT_LOAD_HOME" "$SAT_LOAD_TMP"
export TMPDIR="$SAT_LOAD_TMP"

python3 - "$SAT_LOAD_ROOT/plain.json" <<'PY'
import json
import sys

entries = {}
for index in range(400):
    entries[f"account-{index:03d}"] = {
        "issuer": f"Issuer {index % 20}",
        "account": f"user-{index}@example.invalid",
        "secret": "JBSWY3DPEHPK3PXP",
        "digits": 6,
        "period": 30,
        "algo": "SHA1",
    }
with open(sys.argv[1], "w", encoding="utf-8") as output:
    json.dump(entries, output)
PY

printf '%s' "$SAT_LOAD_PASS" | openssl enc -aes-256-cbc -pbkdf2 -salt -in "$SAT_LOAD_ROOT/plain.json" -out "$SAT_LOAD_HOME/otp.vault" -pass stdin 2>/dev/null

start_ns="$(date +%s%N)"
list_count="$(SAT_HOME="$SAT_LOAD_HOME" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" list --json 3<<<"$SAT_LOAD_PASS" | jq '.entries | length')"
list_elapsed_ms="$((($(date +%s%N) - start_ns) / 1000000))"
[[ "$list_count" -eq 400 ]] || { printf 'FAIL: list returned %s entries\n' "$list_count" >&2; exit 1; }

start_ns="$(date +%s%N)"
code_count="$(SAT_HOME="$SAT_LOAD_HOME" SAT_MASTER_PASS_FD=3 "$SAT_PROJECT_ROOT/sat.sh" codes --json 3<<<"$SAT_LOAD_PASS" | jq '.entries | length')"
codes_elapsed_ms="$((($(date +%s%N) - start_ns) / 1000000))"
[[ "$code_count" -eq 400 ]] || { printf 'FAIL: codes returned %s entries\n' "$code_count" >&2; exit 1; }

((list_elapsed_ms < 5000)) || { printf 'FAIL: list took %sms\n' "$list_elapsed_ms" >&2; exit 1; }
((codes_elapsed_ms < 5000)) || { printf 'FAIL: codes took %sms\n' "$codes_elapsed_ms" >&2; exit 1; }
find "$SAT_LOAD_TMP" -mindepth 1 -print -quit | grep -q . && { printf 'FAIL: process temporary file leaked\n' >&2; exit 1; }
printf '400-entry load checks passed (list=%sms, codes=%sms).\n' "$list_elapsed_ms" "$codes_elapsed_ms"
