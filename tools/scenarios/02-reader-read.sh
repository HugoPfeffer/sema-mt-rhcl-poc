#!/usr/bin/env bash
# Scenario 02 — Authenticated read with a reader API key.
# A valid reader key should be authorized to access /api/read.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

scenario_header "Scenario 02: Reader can access /api/read"

status=$(curl "${CURL_OPTS[@]}" -o /dev/null -w '%{http_code}' \
  -H "Authorization: APIKEY ${RBAC_READER_KEY}" \
  "${BASE_URL}/api/read")
assert_status "GET /api/read — reader key" 200 "$status"
