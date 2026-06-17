#!/usr/bin/env bash
# Scenario 03 — No API key on a protected path.
# Requests without credentials to /api/* must be rejected (401).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

scenario_header "Scenario 03: Unauthenticated request is rejected"

status=$(curl "${CURL_OPTS[@]}" -o /dev/null -w '%{http_code}' "${BASE_URL}/api/read")
assert_status "GET /api/read — no credentials" 401 "$status"
