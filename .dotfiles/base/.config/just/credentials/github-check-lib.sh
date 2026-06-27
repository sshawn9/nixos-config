#!/usr/bin/env bash

readonly API_BASE="https://api.github.com"

CHECKS_TOTAL=0
CHECKS_OK=0
CHECKS_WARN=0
CHECKS_FAIL=0
HARD_FAILS=0
REPORT_ROWS=()
REPO_ROWS=()
ORG_ROWS=()
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
  local body_file headers_file status

  body_file="$(mktemp)"
  headers_file="$(mktemp)"
  status="$(
    curl -sS \
      -D "$headers_file" \
      -w '%{http_code}' \
      -o "$body_file" \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_AUTH_TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$url"
  )" || {
    rm -f "$body_file" "$headers_file"
    return 1
  }

  RESPONSE_BODY="$(<"$body_file")"
  RESPONSE_HEADERS="$(<"$headers_file")"
  RESPONSE_STATUS="$status"
  rm -f "$body_file" "$headers_file"
}

header_value() {
  local name="$1"

  awk -v name="$name" '
    BEGIN { IGNORECASE = 1 }
    index($0, name ":") == 1 {
      sub("^[^:]+:[[:space:]]*", "")
      sub("\r$", "")
      print
      exit
    }
  ' <<<"$RESPONSE_HEADERS"
}

api_succeeded() {
  [[ $RESPONSE_STATUS == 2* ]]
}

error_summary() {
  local message documentation
  message="$(jq -r '.message // empty' <<<"$RESPONSE_BODY" 2>/dev/null || true)"
  documentation="$(jq -r '.documentation_url // empty' <<<"$RESPONSE_BODY" 2>/dev/null || true)"

  if [[ -n $message && -n $documentation ]]; then
    printf '%s (%s)' "$message" "$documentation"
  elif [[ -n $message ]]; then
    printf '%s' "$message"
  else
    printf 'HTTP %s' "$RESPONSE_STATUS"
  fi
}

print_errors() {
  jq -r '
    if (.errors // []) | length > 0 then
      (.errors // [])[] | "       - " + (.message // (.code // "unknown" | tostring))
    else
      empty
    end
  ' <<<"$RESPONSE_BODY"
}

record_repo() {
  local full_name="$1"
  local visibility="$2"
  local permissions="$3"

  [[ -n $full_name && $full_name != "null" ]] || return 0

  local row existing
  for row in "${REPO_ROWS[@]}"; do
    IFS=$'\t' read -r existing _ <<<"$row"
    [[ $existing == "$full_name" ]] && return 0
  done

  REPO_ROWS+=("$full_name"$'\t'"${visibility:-unknown}"$'\t'"${permissions:-unknown}")
}

record_org() {
  local login="$1"

  [[ -n $login && $login != "null" ]] || return 0

  local row
  for row in "${ORG_ROWS[@]}"; do
    [[ $row == "$login" ]] && return 0
  done

  ORG_ROWS+=("$login")
}

repo_permissions() {
  jq -r '
    .permissions // {} |
    to_entries |
    map(select(.value == true) | .key) |
    if length == 0 then "none returned" else join(", ") end
  ' <<<"$1"
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

probe() {
  local section="$1"
  local item="$2"
  local url="$3"
  local success_detail="$4"
  local detail_jq="${5:-}"

  step "$item"
  note "GET $url"

  if ! request "$url"; then
    warn "request failed before GitHub returned a response"
    report "$section" "WARN" "$item" "request failed before GitHub returned a response"
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
  print_rule '-' 104
  printf '  %-6s  %s\n' "STATUS" "CHECK"
  print_rule '-' 104

  for row in "${REPORT_ROWS[@]}"; do
    IFS=$'\t' read -r row_section status item detail <<<"$row"
    [[ $row_section == "$section" ]] || continue
    found=1
    color="$(status_color "$status")"
    printf '  %s%-6s%s  %s\n' "$color" "$status" "$RST" "$item"
    if [[ -n ${detail:-} ]]; then
      printf '          %s\n' "$detail"
    fi
  done

  if ((found == 0)) && [[ $empty_behavior != "hide-empty" ]]; then
    color="$(status_color "SKIP")"
    printf '  %s%-6s%s  %s\n' "$color" "SKIP" "$RST" "No checks recorded"
    printf '          %s\n' "No result was collected for this section."
  fi
}

print_org_rows() {
  ((${#ORG_ROWS[@]} > 0)) || return 0

  local idx org

  printf '\n  %sOrganizations found%s\n' "$BOLD" "$RST"
  printf '  %-4s  %s\n' "#" "ORGANIZATION"
  printf '  '
  print_rule '-' 54

  idx=0
  for org in "${ORG_ROWS[@]}"; do
    idx=$((idx + 1))
    printf '  %-4s  %s\n' "$idx" "$org"
  done
}

print_repo_rows() {
  ((${#REPO_ROWS[@]} > 0)) || return 0

  local idx repo_row full_name visibility permissions

  printf '\n  %sRepositories found%s\n' "$BOLD" "$RST"
  printf '  %-4s  %-44s  %-10s  %s\n' "#" "REPOSITORY" "VISIBILITY" "PERMISSIONS"
  printf '  '
  print_rule '-' 104

  idx=0
  for repo_row in "${REPO_ROWS[@]}"; do
    IFS=$'\t' read -r full_name visibility permissions <<<"$repo_row"
    idx=$((idx + 1))
    printf '  %-4s  %-44s  %-10s  %s\n' "$idx" "$full_name" "$visibility" "$permissions"
  done
}

finish_report() {
  header "GitHub Credential Check Summary"

  printf '\n%sOverview%s\n' "$BOLD" "$RST"
  print_rule '-' 104
  printf '  %-16s %-16s %-16s %-16s\n' "TOTAL" "OK" "WARN" "FAIL"
  print_rule '-' 104
  printf '  %-16s %-16s %-16s %-16s\n' "$CHECKS_TOTAL" "$CHECKS_OK" "$CHECKS_WARN" "$CHECKS_FAIL"

  print_section "token" "Token"
  print_section "identity" "Identity"
  print_section "orgs" "Organizations"
  print_org_rows
  print_section "repos" "Repositories"
  print_repo_rows
  print_section "contents" "Contents" "hide-empty"
  print_section "actions" "Actions" "hide-empty"
  print_section "issues" "Issues And Pull Requests" "hide-empty"
  print_section "releases" "Releases And Deployments" "hide-empty"
  print_section "not-tested" "Not Tested" "hide-empty"

  if ((HARD_FAILS > 0)); then
    printf '\n%sResult:%s FAILED required checks.\n' "$BOLD" "$RST"
    exit 1
  fi

  printf '\n%sResult:%s required checks completed. WARN means unavailable, unauthorized, or intentionally non-destructive.\n' "$BOLD" "$RST"
}
