#!/usr/bin/env bash
# Scenario 06 — Role escalation prevented: writer cannot admin.
# A writer key must NOT be allowed to DELETE via /api/admin (403).
# This proves Connectivity Link enforces tiered RBAC.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

scenario_header "Scenario 06: Writer CANNOT access /api/admin"

status=$(curl "${CURL_OPTS[@]}" -o /dev/null -w '%{http_code}' \
  -X DELETE \
  -H "Authorization: APIKEY ${RBAC_WRITER_KEY}" \
  "${BASE_URL}/api/admin")
assert_status "DELETE /api/admin — writer key (role escalation)" 403 "$status"
