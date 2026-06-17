#!/usr/bin/env bash
# Run every RBAC PoC scenario in order.
# Usage:  ./tools/scenarios/run-all.sh
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

printf '%s\n' "$(_bold "RBAC PoC — Connectivity Link Scenario Suite")"
printf '%s\n' "$(_dim "Target: ${BASE_URL}")"

failures=0

for script in "${SCRIPT_DIR}"/[0-9][0-9]-*.sh; do
  if ! source "$script"; then
    ((failures++)) || true
  fi
done

echo
if [[ $failures -eq 0 ]]; then
  printf '%s\n' "$(_green "All scenarios passed.")"
else
  printf '%s\n' "$(_red "${failures} scenario(s) had failures.")"
  exit 1
fi
