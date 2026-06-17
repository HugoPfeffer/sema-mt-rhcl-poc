#!/usr/bin/env bash
# Scenario 09 — Connectivity Link injects caller identity.
# After authenticating the API key, RHCL injects identity headers
# that the backend echoes back. This proves the gateway performed
# authentication and the app received a verified caller context.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

scenario_header "Scenario 09: Caller identity injected by Connectivity Link"

printf '  %s\n' "$(_dim "Requesting /api/read with admin key and inspecting .caller ...")"
echo

response=$(curl "${CURL_OPTS[@]}" \
  -H "Authorization: APIKEY ${RBAC_ADMIN_KEY}" \
  "${BASE_URL}/api/read")

if command -v jq &>/dev/null; then
  echo "$response" | jq --color-output '.caller // .'
else
  echo "$response"
fi
