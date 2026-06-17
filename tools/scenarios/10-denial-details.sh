#!/usr/bin/env bash
# Scenario 10 — Inspect denial response body and headers.
# When RBAC denies a request, the gateway returns a structured
# error body and an x-rhcl-denied-by header identifying the policy.
# Useful for debugging and proving policy enforcement.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

scenario_header "Scenario 10: Denial response details"

printf '  %s\n' "$(_dim "POST /api/write with reader key — inspecting response headers + body ...")"
echo

curl "${CURL_OPTS[@]}" -D - \
  -X POST \
  -H "Authorization: APIKEY ${RBAC_READER_KEY}" \
  "${BASE_URL}/api/write"
echo
