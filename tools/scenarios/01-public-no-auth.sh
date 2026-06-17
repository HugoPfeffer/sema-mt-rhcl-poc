#!/usr/bin/env bash
# Scenario 01 — Public endpoint requires no authentication.
# The /public path has no AuthPolicy, so any request should succeed.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../env.sh"

scenario_header "Scenario 01: Public endpoint (no auth)"

status=$(curl "${CURL_OPTS[@]}" -o /dev/null -w '%{http_code}' "${BASE_URL}/public")
assert_status "GET /public — no credentials" 200 "$status"
