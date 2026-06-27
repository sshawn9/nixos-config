#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.dotfiles/base/.config/just/credentials/gitee-check-lib.sh
source "$script_dir/gitee-check-lib.sh"

usage() {
  cat <<EOF
Usage: ${0##*/} TOKEN [--deep]

Checks a Gitee personal access token or OAuth access token.

Default mode is lightweight: token, identity, organizations, enterprises, and
repository discovery. Pass --deep to probe repository metadata, contents,
issues, pull requests, and releases for every discovered repository.

The token value and token abbreviation are never printed.
EOF
}

guess_token_type() {
  printf 'Gitee personal access token or OAuth access token'
}

check_user() {
  step "Read authenticated user"
  note "GET $API_BASE/user"

  if ! request "$API_BASE/user"; then
    hard_fail "request failed before Gitee returned a response"
    report "identity" "FAIL" "Authenticated user" "request failed before Gitee returned a response"
    return 0
  fi

  kv "HTTP" "$RESPONSE_STATUS"
  if ! api_succeeded; then
    local err
    err="$(error_summary)"
    hard_fail "authenticated user is not readable: $err"
    print_errors
    report "identity" "FAIL" "Authenticated user" "$err"
    return 0
  fi

  local login name email id
  login="$(jq -r '.login // .username // "unknown"' <<<"$RESPONSE_BODY")"
  name="$(jq -r '.name // "unknown"' <<<"$RESPONSE_BODY")"
  email="$(jq -r '.email // "not returned"' <<<"$RESPONSE_BODY")"
  id="$(jq -r '.id // "unknown"' <<<"$RESPONSE_BODY")"

  ok "authenticated user is readable"
  kv "login" "$login"
  kv "name" "$name"
  kv "email" "$email"
  kv "id" "$id"
  report "identity" "OK" "Authenticated principal" "$login ($name; id: $id; email: $email)"
}

discover_orgs() {
  step "Discover organizations"
  note "GET $API_BASE/user/orgs?per_page=100"

  local url="$API_BASE/user/orgs?per_page=100"
  local total=0 page=0

  while [[ -n $url ]]; do
    page=$((page + 1))
    if ! request "$url"; then
      warn "request failed before Gitee returned a response"
      report "orgs" "WARN" "Organization discovery" "request failed before Gitee returned a response"
      return 0
    fi

    kv "HTTP page $page" "$RESPONSE_STATUS"
    if ! api_succeeded; then
      local err
      err="$(error_summary)"
      warn "organizations are not readable: $err"
      print_errors
      report "orgs" "WARN" "Organization discovery" "$err"
      return 0
    fi

    local count
    count="$(jq -r 'if type == "array" then length else 0 end' <<<"$RESPONSE_BODY")"
    total=$((total + count))

    while IFS=$'\t' read -r login display; do
      [[ -n $login ]] || continue
      record_org "$login" "$display"
    done < <(
      jq -r '
        if type == "array" then
          .[] |
          [
            (.login // .path // .name // empty),
            (.name // .login // .path // "")
          ] |
          @tsv
        else
          empty
        end
      ' <<<"$RESPONSE_BODY"
    )

    url="$(next_link)"
  done

  ok "organizations are readable"
  kv "organizations" "$total"
  report "orgs" "OK" "Organization discovery" "$total organization item(s) across $page page(s)"
}

discover_enterprises() {
  step "Discover enterprises"
  note "GET $API_BASE/enterprises"

  local url="$API_BASE/enterprises"
  local total=0 page=0

  while [[ -n $url ]]; do
    page=$((page + 1))
    if ! request "$url"; then
      warn "request failed before Gitee returned a response"
      report "enterprises" "WARN" "Enterprise discovery" "request failed before Gitee returned a response"
      return 0
    fi

    kv "HTTP page $page" "$RESPONSE_STATUS"
    if ! api_succeeded; then
      local err
      err="$(error_summary)"
      warn "enterprises are not readable: $err"
      print_errors
      report "enterprises" "WARN" "Enterprise discovery" "$err"
      return 0
    fi

    local count
    count="$(jq -r 'if type == "array" then length else 0 end' <<<"$RESPONSE_BODY")"
    total=$((total + count))

    while IFS=$'\t' read -r path display; do
      [[ -n $path ]] || continue
      record_enterprise "$path" "$display"
    done < <(
      jq -r '
        if type == "array" then
          .[] |
          [
            (.path // .login // .name // empty),
            (.name // .path // .login // "")
          ] |
          @tsv
        else
          empty
        end
      ' <<<"$RESPONSE_BODY"
    )

    url="$(next_link)"
  done

  ok "enterprises are readable"
  kv "enterprises" "$total"
  report "enterprises" "OK" "Enterprise discovery" "$total enterprise item(s) across $page page(s)"
}

discover_repos() {
  step "Discover repositories"
  note "GET $API_BASE/user/repos?per_page=100"

  local url="$API_BASE/user/repos?per_page=100"
  local total=0 page=0

  while [[ -n $url ]]; do
    page=$((page + 1))
    if ! request "$url"; then
      warn "request failed before Gitee returned a response"
      report "repos" "WARN" "Repository discovery" "request failed before Gitee returned a response"
      return 0
    fi

    kv "HTTP page $page" "$RESPONSE_STATUS"
    if ! api_succeeded; then
      local err
      err="$(error_summary)"
      warn "repositories are not readable: $err"
      print_errors
      report "repos" "WARN" "Repository discovery" "$err"
      return 0
    fi

    local count
    count="$(jq -r 'if type == "array" then length else 0 end' <<<"$RESPONSE_BODY")"
    total=$((total + count))

    while IFS=$'\t' read -r full_name visibility permissions; do
      [[ -n $full_name ]] || continue
      record_repo "$full_name" "$visibility" "$permissions"
    done < <(
      jq -r '
        if type == "array" then
          .[] |
          [
            (
              .full_name //
              (
                ((.namespace.path // .namespace.name // .owner.login // .owner.name // .owner // "") | tostring) +
                "/" +
                ((.path // .name // "") | tostring)
              )
            ),
            (.visibility // (if .private == true then "private" elif .public == true then "public" else "unknown" end)),
            (
              .permissions // {} |
              if type == "object" then
                to_entries |
                map(select(.value == true) | .key) |
                if length == 0 then "not returned" else join(", ") end
              else
                "not returned"
              end
            )
          ] |
          @tsv
        else
          empty
        end
      ' <<<"$RESPONSE_BODY"
    )

    url="$(next_link)"
  done

  ok "repositories are readable"
  kv "repositories" "$total"
  report "repos" "OK" "Repository discovery" "$total repository item(s) across $page page(s)"
}

probe_repo() {
  local full_name="$1"
  local visibility="$2"
  local permissions="$3"

  probe "repos" "Repository metadata: $full_name" "$API_BASE/repos/$full_name" "metadata readable; visibility=$visibility; permissions=$permissions"
  probe "contents" "Repository contents: $full_name" "$API_BASE/repos/$full_name/contents" "contents API is readable"
  probe "issues" "Issues: $full_name" "$API_BASE/repos/$full_name/issues?per_page=1" "issues endpoint is readable" '"issue items visible: " + (if type == "array" then length else 0 end | tostring)'
  probe "issues" "Pull requests: $full_name" "$API_BASE/repos/$full_name/pulls?per_page=1" "pull requests endpoint is readable" '"pull request items visible: " + (if type == "array" then length else 0 end | tostring)'
  probe "releases" "Releases: $full_name" "$API_BASE/repos/$full_name/releases?per_page=1" "releases endpoint is readable" '"release items visible: " + (if type == "array" then length else 0 end | tostring)'
}

main() {
  case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  esac

  if (($# < 1 || $# > 2)); then
    die "usage: ${0##*/} TOKEN [--deep]"
  fi

  GITEE_AUTH_TOKEN="$1"
  local mode="${2:-}"
  if [[ -n $mode && $mode != "--deep" ]]; then
    die "unknown option: $mode"
  fi

  require_cmd curl
  require_cmd jq

  header "Gitee Token Check"
  report "token" "OK" "Detected token model" "$(guess_token_type)"
  if [[ $mode == "--deep" ]]; then
    report "token" "OK" "Probe mode" "deep"
  else
    report "token" "OK" "Probe mode" "lightweight"
  fi

  check_user
  discover_orgs
  discover_enterprises
  discover_repos

  if ((${#REPO_ROWS[@]} == 0)); then
    report "not-tested" "SKIP" "Repository-scoped probes" "no repositories were discovered"
  elif [[ $mode == "--deep" ]]; then
    local repo_row full_name visibility permissions
    for repo_row in "${REPO_ROWS[@]}"; do
      IFS=$'\t' read -r full_name visibility permissions <<<"$repo_row"
      probe_repo "$full_name" "$visibility" "$permissions"
    done
  fi

  finish_report
}

main "$@"
