#!/usr/bin/env bash
# SAT - Silent Authenticator Tool

set -euo pipefail

SAT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# shellcheck source=lib/common.sh
source "$SAT_ROOT/lib/common.sh"
# shellcheck source=lib/ui.sh
source "$SAT_ROOT/lib/ui.sh"
# shellcheck source=lib/vault.sh
source "$SAT_ROOT/lib/vault.sh"
# shellcheck source=lib/commands.sh
source "$SAT_ROOT/lib/commands.sh"

main "$@"
