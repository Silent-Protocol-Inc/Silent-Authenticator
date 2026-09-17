#!/usr/bin/env bash

set -euo pipefail

SAT_PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
SAT_TEST_UI_HOME="$(mktemp -d "${TMPDIR:-/tmp}/sat-ui-test.XXXXXX")"
trap 'rm -rf -- "$SAT_TEST_UI_HOME"' EXIT

SAT_ROOT="$SAT_PROJECT_ROOT"
SAT_HOME="$SAT_TEST_UI_HOME/home"
SAT_LANG=id
source "$SAT_PROJECT_ROOT/lib/common.sh"
source "$SAT_PROJECT_ROOT/lib/ui.sh"

[[ "$(ui_parse_boolean Y)" == yes ]]
[[ "$(ui_parse_boolean ya)" == yes ]]
[[ "$(ui_parse_boolean NO)" == no ]]
[[ "$(ui_parse_boolean tidak)" == no ]]
ui_parse_boolean perhaps >/dev/null && exit 1

SAT_LANG=en
save_language
SAT_LANG=id
SAT_LANG_EXPLICIT=no
load_saved_language
[[ "$SAT_LANG" == en ]]
[[ "$(stat -c '%a' "$SAT_CONFIG_FILE")" == 600 ]]

printf 'Terminal UI checks passed.\n'
