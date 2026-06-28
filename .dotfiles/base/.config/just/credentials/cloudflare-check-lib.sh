#!/usr/bin/env bash

readonly API_BASE="https://api.cloudflare.com/client/v4"

CHECKS_TOTAL=0
CHECKS_OK=0
CHECKS_WARN=0
CHECKS_FAIL=0
HARD_FAILS=0
REPORT_ROWS=()
ACCOUNT_ROWS=()
ZONE_ROWS=()
BOLD=""
DIM=""
GREEN=""
YELLOW=""
RED=""
RST=""

setup_colors() {
  if [[ -t 1 ]]; then
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    RED=$'\033[31m'
    RST=$'\033[0m'
  fi
}

setup_colors

die() {
  echo "Error: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 ||
    die "$1 not found in PATH."
}

header() {
  printf '\n%s%s%s\n' "$BOLD" "$1" "$RST"
  printf '%s\n' "$(printf '%*s' "${#1}" '' | tr ' ' '=')"
}

step() {
  CHECKS_TOTAL=$((CHECKS_TOTAL + 1))
  printf '\n[%02d] %s\n' "$CHECKS_TOTAL" "$1"
}

note() {
  printf '  NOTE %s\n' "$1"
}

kv() {
  printf '       %-18s %s\n' "$1:" "$2"
}

report() {
  local section="$1"
  local status="$2"
  local item="$3"
  local detail="$4"

  REPORT_ROWS+=("$section"$'\t'"$status"$'\t'"$item"$'\t'"$detail")
}

ok() {
  CHECKS_OK=$((CHECKS_OK + 1))
  printf '  %sOK%s   %s\n' "$GREEN" "$RST" "$1"
}

warn() {
  CHECKS_WARN=$((CHECKS_WARN + 1))
  printf '  %sWARN%s %s\n' "$YELLOW" "$RST" "$1"
}

fail() {
  CHECKS_FAIL=$((CHECKS_FAIL + 1))
  printf '  %sFAIL%s %s\n' "$RED" "$RST" "$1"
}

hard_fail() {
  HARD_FAILS=$((HARD_FAILS + 1))
  fail "$1"
}

request() {
  local url="$1"
  local body_file status

  body_file="$(mktemp)"
  status="$(
    curl -sS \
      -w '%{http_code}' \
      -o "$body_file" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN_VALUE" \
      "$url"
  )" || {
    rm -f "$body_file"
    return 1
  }

  RESPONSE_BODY="$(<"$body_file")"
  RESPONSE_STATUS="$status"
  rm -f "$body_file"
}

json_success() {
  jq -e '.success == true' >/dev/null <<<"$RESPONSE_BODY"
}

api_succeeded() {
  [[ $RESPONSE_STATUS == 2* ]] && json_success
}

error_summary() {
  local summary errors_count
  errors_count="$(jq -r '(.errors // []) | length' <<<"$RESPONSE_BODY" 2>/dev/null || printf '0')"

  if [[ $errors_count == "0" ]]; then
    printf 'HTTP %s' "$RESPONSE_STATUS"
    return
  fi

  summary="$(
    jq -r '
      (.errors // []) |
      map(((.code // "unknown") | tostring) + ": " + (.message // "unknown")) |
      join("; ")
    ' <<<"$RESPONSE_BODY"
  )"
  printf '%s' "$summary"
}

has_error_code() {
  local code="$1"
  jq -r '(.errors // [])[] | .code // empty' <<<"$RESPONSE_BODY" | grep -qx "$code"
}

print_errors() {
  jq -r '
    (.errors // [])[] |
    "       - " + ((.code // "unknown") | tostring) + ": " + (.message // "unknown")
  ' <<<"$RESPONSE_BODY"
}

record_account() {
  local id="$1"
  local name="$2"

  [[ -n $id && $id != "null" ]] || return 0

  local row existing_id
  for row in "${ACCOUNT_ROWS[@]}"; do
    IFS=$'\t' read -r existing_id _ <<<"$row"
    [[ $existing_id == "$id" ]] && return 0
  done

  ACCOUNT_ROWS+=("$id"$'\t'"${name:-unknown}")
}

record_zone() {
  local id="$1"
  local name="$2"
  local account_id="$3"
  local account_name="$4"

  [[ -n $id && $id != "null" ]] || return 0

  local row existing_id
  for row in "${ZONE_ROWS[@]}"; do
    IFS=$'\t' read -r existing_id _ <<<"$row"
    [[ $existing_id == "$id" ]] && return 0
  done

  ZONE_ROWS+=("$id"$'\t'"${name:-unknown}"$'\t'"${account_id:-unknown}"$'\t'"${account_name:-unknown}")
}

account_label() {
  local id="$1"
  local name="$2"
  printf '%s (%s)' "${name:-unknown}" "$id"
}

zone_label() {
  local id="$1"
  local name="$2"
  printf '%s (%s)' "${name:-unknown}" "$id"
}

result_count() {
  jq -r '
    if (.result | type) == "array" then
      .result | length
    else
      "available"
    end
  ' <<<"$RESPONSE_BODY"
}

probe() {
  local section="$1"
  local item="$2"
  local url="$3"
  local success_detail="$4"
  local detail_jq="${5:-}"

  step "$item"
  note "GET $url"

  if ! request "$url"; then
    warn "request failed before Cloudflare returned a response"
    report "$section" "WARN" "$item" "request failed before Cloudflare returned a response"
    return 0
  fi

  kv "HTTP" "$RESPONSE_STATUS"
  if api_succeeded; then
    local detail="$success_detail"
    if [[ -n $detail_jq ]]; then
      detail="$(jq -r "$detail_jq" <<<"$RESPONSE_BODY")"
    fi
    ok "$detail"
    report "$section" "OK" "$item" "$detail"
  else
    local err
    err="$(error_summary)"
    warn "not available: $err"
    print_errors
    report "$section" "WARN" "$item" "$err"
  fi
}

status_color() {
  local status="$1"

  case "$status" in
  OK) printf '%s' "$GREEN" ;;
  WARN) printf '%s' "$YELLOW" ;;
  FAIL) printf '%s' "$RED" ;;
  SKIP) printf '%s' "$DIM" ;;
  *) printf '' ;;
  esac
}

print_rule() {
  local char="$1"
  local width="$2"
  printf '%*s\n' "$width" '' | tr ' ' "$char"
}

print_section() {
  local section="$1"
  local title="$2"
  local empty_behavior="${3:-show-empty}"
  local found=0 row row_section status item detail color

  if [[ $empty_behavior == "hide-empty" ]]; then
    for row in "${REPORT_ROWS[@]}"; do
      IFS=$'\t' read -r row_section _ <<<"$row"
      if [[ $row_section == "$section" ]]; then
        found=1
        break
      fi
    done

    ((found == 1)) || return 0
    found=0
  fi

  printf '\n%s%s%s\n' "$BOLD" "$title" "$RST"
  print_rule '-' 96
  printf '  %-6s  %-36s  %s\n' "STATUS" "CHECK" "RESULT"
  print_rule '-' 96

  for row in "${REPORT_ROWS[@]}"; do
    IFS=$'\t' read -r row_section status item detail <<<"$row"
    [[ $row_section == "$section" ]] || continue
    found=1
    color="$(status_color "$status")"
    printf '  %s%-6s%s  %-36s  %s\n' "$color" "$status" "$RST" "$item" "${detail:-}"
  done

  if ((found == 0)) && [[ $empty_behavior != "hide-empty" ]]; then
    color="$(status_color "SKIP")"
    printf '  %s%-6s%s  %-36s  %s\n' "$color" "SKIP" "$RST" "No checks recorded" "No result was collected for this section."
  fi
}

print_account_rows() {
  ((${#ACCOUNT_ROWS[@]} > 0)) || return 0

  local idx account_row account_id account_name

  printf '\n  %sAccounts found%s\n' "$BOLD" "$RST"
  printf '  %-4s  %-34s  %s\n' "#" "ACCOUNT ID" "ACCOUNT NAME"
  printf '  '
  print_rule '-' 96

  idx=0
  for account_row in "${ACCOUNT_ROWS[@]}"; do
    IFS=$'\t' read -r account_id account_name <<<"$account_row"
    idx=$((idx + 1))
    printf '  %-4s  %-34s  %s\n' "$idx" "$account_id" "$account_name"
  done
}

print_zone_rows() {
  ((${#ZONE_ROWS[@]} > 0)) || return 0

  local idx zone_row zone_id zone_name account_id account_name

  printf '\n  %sZones found%s\n' "$BOLD" "$RST"
  printf '  %-4s  %-30s  %-34s  %-24s  %s\n' "#" "DOMAIN" "ZONE ID" "ACCOUNT NAME" "ACCOUNT ID"
  printf '  '
  print_rule '-' 128

  idx=0
  for zone_row in "${ZONE_ROWS[@]}"; do
    IFS=$'\t' read -r zone_id zone_name account_id account_name <<<"$zone_row"
    idx=$((idx + 1))
    printf '  %-4s  %-30s  %-34s  %-24s  %s\n' "$idx" "$zone_name" "$zone_id" "$account_name" "$account_id"
  done
}

finish_report() {
  header "Cloudflare Credential Check Summary"

  printf '\n%sOverview%s\n' "$BOLD" "$RST"
  print_rule '-' 96
  printf '  %-16s %-16s %-16s %-16s\n' "TOTAL" "OK" "WARN" "FAIL"
  print_rule '-' 96
  printf '  %-16s %-16s %-16s %-16s\n' "$CHECKS_TOTAL" "$CHECKS_OK" "$CHECKS_WARN" "$CHECKS_FAIL"

  print_section "token" "Token"
  print_section "user" "User Context"
  print_section "accounts" "Accounts"
  print_account_rows
  print_section "zones" "Zones"
  print_zone_rows
  print_section "workers" "Workers"
  print_section "pages" "Pages"
  print_section "not-tested" "Not Tested" "hide-empty"

  if ((HARD_FAILS > 0)); then
    printf '\n%sResult:%s FAILED required checks.\n' "$BOLD" "$RST"
    exit 1
  fi

  printf '\n%sResult:%s required checks completed. WARN means unavailable, unauthorized, or intentionally non-destructive.\n' "$BOLD" "$RST"
}
