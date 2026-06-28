#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.dotfiles/base/.config/just/credentials/cloudflare-check-lib.sh
source "$script_dir/cloudflare-check-lib.sh"

usage() {
  cat <<EOF
Usage: ${0##*/} CFUT_TOKEN

Checks a Cloudflare user API token (cfut_*).

The script discovers visible accounts and zones, then runs non-destructive
capability probes for every discovered account and zone. It never prints the
token value, token abbreviation, or Cloudflare token id.
EOF
}

check_user_token() {
  step "Verify user API token"
  note "GET $API_BASE/user/tokens/verify"

  if ! request "$API_BASE/user/tokens/verify"; then
    hard_fail "request failed before Cloudflare returned a response"
    report "token" "FAIL" "User token verification" "request failed before Cloudflare returned a response"
    return
  fi

  kv "HTTP" "$RESPONSE_STATUS"
  if ! api_succeeded; then
    local err
    err="$(error_summary)"
    hard_fail "token verify failed: $err"
    print_errors
    report "token" "FAIL" "User token verification" "$err"
    return
  fi

  local status
  status="$(jq -r '.result.status // "unknown"' <<<"$RESPONSE_BODY")"
  CLOUDFLARE_TOKEN_ID="$(jq -r '.result.id // empty' <<<"$RESPONSE_BODY")"
  kv "status" "$status"

  if [[ $status == "active" ]]; then
    ok "user token is active"
    report "token" "OK" "Token type" "cfut_ user API token"
    report "token" "OK" "Token status" "$status"
  else
    hard_fail "user token is not active"
    report "token" "FAIL" "Token status" "$status"
  fi
}

check_user_token_details() {
  step "Read user token permission details"

  if [[ -z ${CLOUDFLARE_TOKEN_ID:-} ]]; then
    warn "verify did not return a token id; cannot request token details"
    report "token" "WARN" "Permission introspection" "verify did not return a token id"
    return
  fi

  note "GET $API_BASE/user/tokens/{token_id}"
  if ! request "$API_BASE/user/tokens/$CLOUDFLARE_TOKEN_ID"; then
    warn "request failed before Cloudflare returned a response"
    report "token" "WARN" "Permission introspection" "request failed before Cloudflare returned a response"
    return
  fi

  kv "HTTP" "$RESPONSE_STATUS"
  if ! api_succeeded; then
    if has_error_code "9109"; then
      warn "Cloudflare did not allow this token to read token-management details"
      report "token" "WARN" "Permission introspection" "Cloudflare returned 9109; concrete API probes are more reliable than token self-inspection"
    else
      local err
      err="$(error_summary)"
      warn "token details are not readable: $err"
      print_errors
      report "token" "WARN" "Permission introspection" "$err"
    fi
    return
  fi

  local permissions
  permissions="$(
    jq -r '
      [
        .result.policies[]? |
        .permission_groups[]? |
        .name // .id // empty
      ] |
      unique |
      .[]
    ' <<<"$RESPONSE_BODY"
  )"

  if [[ -z $permissions ]]; then
    ok "token details are readable, but no permission groups were returned"
    report "token" "OK" "Permission introspection" "readable; no permission groups returned"
  else
    ok "token details are readable"
    printf '%s\n' "$permissions" | sed 's/^/       - /'
    report "token" "OK" "Permission groups" "$(paste -sd ', ' <<<"$permissions")"
  fi
}

discover_user_profile() {
  step "Read user profile"
  note "GET $API_BASE/user"

  if ! request "$API_BASE/user"; then
    warn "request failed before Cloudflare returned a response"
    report "user" "WARN" "User profile" "request failed before Cloudflare returned a response"
    return
  fi

  kv "HTTP" "$RESPONSE_STATUS"
  if api_succeeded; then
    local user
    user="$(jq -r '.result.email // .result.username // .result.id // "unknown"' <<<"$RESPONSE_BODY")"
    ok "user profile is readable"
    kv "user" "$user"
    report "user" "OK" "User profile" "$user"
  else
    local err
    err="$(error_summary)"
    warn "user profile is not readable: $err"
    print_errors
    report "user" "WARN" "User profile" "$err"
  fi
}

discover_memberships() {
  step "Discover account memberships"
  note "GET $API_BASE/memberships"

  if ! request "$API_BASE/memberships"; then
    warn "request failed before Cloudflare returned a response"
    report "accounts" "WARN" "Membership discovery" "request failed before Cloudflare returned a response"
    return
  fi

  kv "HTTP" "$RESPONSE_STATUS"
  if ! api_succeeded; then
    local err
    err="$(error_summary)"
    warn "memberships are not readable: $err"
    print_errors
    report "accounts" "WARN" "Membership discovery" "$err"
    return
  fi

  local count
  count="$(jq -r '.result | length' <<<"$RESPONSE_BODY")"
  ok "memberships are readable"
  kv "accounts" "$count"
  report "accounts" "OK" "Membership discovery" "$count account(s)"

  while IFS=$'\t' read -r id name; do
    [[ -n $id ]] || continue
    record_account "$id" "$name"
    kv "account" "$(account_label "$id" "$name")"
  done < <(jq -r '.result[]? | [.account.id, (.account.name // "unknown")] | @tsv' <<<"$RESPONSE_BODY")
}

discover_accounts() {
  step "Discover accounts via account list"
  note "GET $API_BASE/accounts"

  if ! request "$API_BASE/accounts"; then
    warn "request failed before Cloudflare returned a response"
    report "accounts" "WARN" "Account list" "request failed before Cloudflare returned a response"
    return
  fi

  kv "HTTP" "$RESPONSE_STATUS"
  if ! api_succeeded; then
    local err
    err="$(error_summary)"
    warn "account list is not readable: $err"
    print_errors
    report "accounts" "WARN" "Account list" "$err"
    return
  fi

  local count
  count="$(jq -r '.result | length' <<<"$RESPONSE_BODY")"
  ok "account list is readable"
  kv "accounts" "$count"
  report "accounts" "OK" "Account list" "$count account(s)"

  while IFS=$'\t' read -r id name; do
    [[ -n $id ]] || continue
    record_account "$id" "$name"
  done < <(jq -r '.result[]? | [.id, (.name // "unknown")] | @tsv' <<<"$RESPONSE_BODY")
}

discover_zones() {
  step "Discover zones"
  note "GET $API_BASE/zones?per_page=50"

  if ! request "$API_BASE/zones?per_page=50"; then
    warn "request failed before Cloudflare returned a response"
    report "zones" "WARN" "Zone discovery" "request failed before Cloudflare returned a response"
    return
  fi

  kv "HTTP" "$RESPONSE_STATUS"
  if ! api_succeeded; then
    local err
    err="$(error_summary)"
    warn "zone list is not readable: $err"
    print_errors
    report "zones" "WARN" "Zone discovery" "$err"
    return
  fi

  local count
  count="$(jq -r '.result | length' <<<"$RESPONSE_BODY")"
  ok "zone list is readable"
  kv "zones" "$count"
  report "zones" "OK" "Zone discovery" "$count zone(s)"

  while IFS=$'\t' read -r id name account_id account_name; do
    [[ -n $id ]] || continue
    record_zone "$id" "$name" "$account_id" "$account_name"
    record_account "$account_id" "$account_name"
    kv "zone" "$(zone_label "$id" "$name")"
    kv "account" "$(account_label "$account_id" "$account_name")"
  done < <(jq -r '.result[]? | [.id, (.name // "unknown"), (.account.id // ""), (.account.name // "unknown")] | @tsv' <<<"$RESPONSE_BODY")
}

probe_zone() {
  local zone_id="$1"
  local zone_name="$2"
  local zone
  zone="$(zone_label "$zone_id" "$zone_name")"

  probe "zones" "Zone detail: $zone" "$API_BASE/zones/$zone_id" "zone is readable"
  probe "zones" "DNS records: $zone" "$API_BASE/zones/$zone_id/dns_records?per_page=1" "DNS records are readable" '"DNS record items visible: " + ((.result | length) | tostring)'
  probe "zones" "Zone rulesets: $zone" "$API_BASE/zones/$zone_id/rulesets" "zone rulesets are readable" '"ruleset items visible: " + ((.result | length) | tostring)'
  probe "zones" "SSL/TLS setting: $zone" "$API_BASE/zones/$zone_id/settings/ssl" "SSL/TLS setting is readable"
}

probe_account() {
  local account_id="$1"
  local account_name="$2"
  local account
  account="$(account_label "$account_id" "$account_name")"

  probe "accounts" "Account detail: $account" "$API_BASE/accounts/$account_id" "account detail is readable"
  probe "workers" "Workers scripts: $account" "$API_BASE/accounts/$account_id/workers/scripts?per_page=1" "Workers scripts are readable" '"script items visible: " + ((.result | length) | tostring)'
  probe "workers" "Workers custom domains: $account" "$API_BASE/accounts/$account_id/workers/domains/records?per_page=1" "Workers custom domains are readable" '"custom domain items visible: " + ((.result | length) | tostring)'
  probe "pages" "Pages projects: $account" "$API_BASE/accounts/$account_id/pages/projects?per_page=1" "Pages projects are readable" '"project items visible: " + ((.result | length) | tostring)'
}

main() {
  case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  esac

  (($# == 1)) || die "this script accepts exactly one argument: CFUT_TOKEN."

  CLOUDFLARE_API_TOKEN_VALUE="$1"
  require_cmd curl
  require_cmd jq

  [[ $CLOUDFLARE_API_TOKEN_VALUE == cfut_* ]] ||
    die "this script expects a cfut_* user API token."

  header "Cloudflare User Token Check"
  kv "token type" "cfut_ user API token"

  check_user_token
  check_user_token_details
  discover_user_profile
  discover_memberships
  discover_accounts
  discover_zones

  if ((${#ZONE_ROWS[@]} == 0)); then
    report "not-tested" "SKIP" "Zone-scoped probes" "no zones were discovered"
  else
    local zone_row zone_id zone_name zone_account_id zone_account_name
    for zone_row in "${ZONE_ROWS[@]}"; do
      IFS=$'\t' read -r zone_id zone_name zone_account_id zone_account_name <<<"$zone_row"
      probe_zone "$zone_id" "$zone_name"
    done
  fi

  if ((${#ACCOUNT_ROWS[@]} == 0)); then
    report "not-tested" "SKIP" "Account-scoped probes" "no accounts were discovered"
  else
    local account_row account_id account_name
    for account_row in "${ACCOUNT_ROWS[@]}"; do
      IFS=$'\t' read -r account_id account_name <<<"$account_row"
      probe_account "$account_id" "$account_name"
    done
  fi

  finish_report
}

main "$@"
