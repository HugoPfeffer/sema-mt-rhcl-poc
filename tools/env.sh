#!/usr/bin/env bash
# Shared configuration for RBAC PoC scenario scripts.
# Pulls host and API keys live from the connected OpenShift cluster.
# Source this file; do not execute it directly.

# Guard: skip re-initialization if already sourced in this process tree.
if [[ -n "${_RBAC_ENV_LOADED:-}" ]]; then return 0 2>/dev/null || true; fi

RBAC_NAMESPACE="${RBAC_NAMESPACE:-rbac-poc}"
RBAC_GW_NAMESPACE="${RBAC_GW_NAMESPACE:-ingress-gateway}"
RBAC_GW_SERVICE="${RBAC_GW_SERVICE:-prod-web-istio}"
RBAC_LOCAL_PORT="${RBAC_LOCAL_PORT:-8443}"
CURL_TIMEOUT="${CURL_TIMEOUT:-10}"

# ---------------------------------------------------------------------------
# Output helpers (defined early — used by connectivity checks below)
# ---------------------------------------------------------------------------
_green()  { printf '\033[0;32m%s\033[0m' "$*"; }
_red()    { printf '\033[0;31m%s\033[0m' "$*"; }
_cyan()   { printf '\033[0;36m%s\033[0m' "$*"; }
_bold()   { printf '\033[1m%s\033[0m' "$*"; }
_dim()    { printf '\033[2m%s\033[0m' "$*"; }

assert_status() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    printf '  %s  %-45s %s\n' "$(_green "✔ PASS")" "$label" "$(_dim "HTTP $actual")"
    return 0
  else
    printf '  %s  %-45s %s %s\n' "$(_red "✘ FAIL")" "$label" "$(_red "HTTP $actual")" "$(_dim "(expected $expected)")"
    return 1
  fi
}

scenario_header() {
  printf '\n%s  %s\n' "$(_cyan "▸")" "$(_bold "$*")"
  printf '%s\n' "$(_dim "$(printf '%.0s─' {1..60})")"
}

# ---------------------------------------------------------------------------
# Resolve host from the HTTPRoute
# ---------------------------------------------------------------------------
if [[ -z "${RBAC_HOST:-}" ]]; then
  RBAC_HOST=$(oc get httproute rbac-sample-api -n "${RBAC_NAMESPACE}" \
    -o jsonpath='{.spec.hostnames[0]}' 2>/dev/null) \
    || { echo "ERROR: cannot read HTTPRoute rbac-sample-api in ${RBAC_NAMESPACE}. Are you logged in? (oc login)" >&2; exit 1; }
fi

# ---------------------------------------------------------------------------
# Resolve API keys from the Authorino-managed Secrets
# ---------------------------------------------------------------------------
_get_key() {
  oc get secret "$1" -n "${RBAC_NAMESPACE}" \
    -o jsonpath='{.data.api_key}' 2>/dev/null | base64 -d
}

if [[ -z "${RBAC_ADMIN_KEY:-}" ]]; then
  RBAC_ADMIN_KEY=$(_get_key apikey-admin) \
    || { echo "ERROR: cannot read secret apikey-admin in ${RBAC_NAMESPACE}" >&2; exit 1; }
fi
if [[ -z "${RBAC_WRITER_KEY:-}" ]]; then
  RBAC_WRITER_KEY=$(_get_key apikey-writer) \
    || { echo "ERROR: cannot read secret apikey-writer in ${RBAC_NAMESPACE}" >&2; exit 1; }
fi
if [[ -z "${RBAC_READER_KEY:-}" ]]; then
  RBAC_READER_KEY=$(_get_key apikey-reader) \
    || { echo "ERROR: cannot read secret apikey-reader in ${RBAC_NAMESPACE}" >&2; exit 1; }
fi

export RBAC_HOST RBAC_ADMIN_KEY RBAC_WRITER_KEY RBAC_READER_KEY

# ---------------------------------------------------------------------------
# Connectivity: direct or port-forward through the ingress gateway
# ---------------------------------------------------------------------------
_can_reach_host() {
  curl -sk --connect-timeout 3 --max-time 5 -o /dev/null \
    "https://${RBAC_HOST}/public" 2>/dev/null
}

_start_port_forward() {
  # Re-use existing port-forward (from this or a parent process).
  if curl -sk --connect-timeout 1 -o /dev/null "https://localhost:${RBAC_LOCAL_PORT}" 2>/dev/null; then
    return 0
  fi
  printf '%s\n' "$(_dim "Starting port-forward ${RBAC_GW_SERVICE}:443 → localhost:${RBAC_LOCAL_PORT} ...")"
  oc port-forward "svc/${RBAC_GW_SERVICE}" "${RBAC_LOCAL_PORT}:443" \
    -n "${RBAC_GW_NAMESPACE}" &>/dev/null &
  _RBAC_PF_PID=$!
  export _RBAC_PF_PID
  sleep 2
  if ! kill -0 "$_RBAC_PF_PID" 2>/dev/null; then
    echo "ERROR: port-forward to ${RBAC_GW_SERVICE} failed" >&2; exit 1
  fi
  trap 'kill $_RBAC_PF_PID 2>/dev/null' EXIT
}

CURL_OPTS=( -sk --connect-timeout "${CURL_TIMEOUT}" --max-time $((CURL_TIMEOUT * 3)) )

if _can_reach_host; then
  BASE_URL="https://${RBAC_HOST}"
  printf '%s\n' "$(_dim "Connectivity: direct → ${RBAC_HOST}")"
else
  _start_port_forward
  CURL_OPTS+=( --resolve "${RBAC_HOST}:${RBAC_LOCAL_PORT}:127.0.0.1" )
  BASE_URL="https://${RBAC_HOST}:${RBAC_LOCAL_PORT}"
  printf '%s\n' "$(_dim "Connectivity: port-forward → localhost:${RBAC_LOCAL_PORT}")"
fi

export _RBAC_ENV_LOADED=1 BASE_URL
export CURL_OPTS_STR="${CURL_OPTS[*]}"
