#!/usr/bin/env bash
# Scenario 07 — Admin has full access.
# An admin key should be permitted to DELETE via /api/admin.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

scenario_header "Scenario 07: Admin can access /api/admin"

status=$(curl "${CURL_OPTS[@]}" -o /dev/null -w '%{http_code}' \
  -X DELETE \
  -H "Authorization: APIKEY ${RBAC_ADMIN_KEY}" \
  "${BASE_URL}/api/admin")
assert_status "DELETE /api/admin — admin key" 200 "$status"
