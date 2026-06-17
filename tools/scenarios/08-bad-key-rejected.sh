#!/usr/bin/env bash
# Scenario 08 — Invalid API key is rejected.
# A fabricated key must fail authentication (401).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

scenario_header "Scenario 08: Invalid API key is rejected"

status=$(curl "${CURL_OPTS[@]}" -o /dev/null -w '%{http_code}' \
  -H "Authorization: APIKEY totally-bogus-key" \
  "${BASE_URL}/api/read")
assert_status "GET /api/read — invalid key" 401 "$status"
