#!/usr/bin/env bash
# Scenario 04 — Authorized write with a writer API key.
# A writer key should be permitted to POST to /api/write.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

scenario_header "Scenario 04: Writer can access /api/write"

status=$(curl "${CURL_OPTS[@]}" -o /dev/null -w '%{http_code}' \
  -X POST \
  -H "Authorization: APIKEY ${RBAC_WRITER_KEY}" \
  "${BASE_URL}/api/write")
assert_status "POST /api/write — writer key" 200 "$status"
