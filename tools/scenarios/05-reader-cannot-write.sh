#!/usr/bin/env bash
# Scenario 05 — Role escalation prevented: reader cannot write.
# A reader key must NOT be allowed to POST to /api/write (403).
# This proves Connectivity Link enforces role-based access control.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

scenario_header "Scenario 05: Reader CANNOT access /api/write"

status=$(curl "${CURL_OPTS[@]}" -o /dev/null -w '%{http_code}' \
  -X POST \
  -H "Authorization: APIKEY ${RBAC_READER_KEY}" \
  "${BASE_URL}/api/write")
assert_status "POST /api/write — reader key (role escalation)" 403 "$status"
