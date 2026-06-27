#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.dotfiles/base/.config/just/credentials/github-check-lib.sh
source "$script_dir/github-check-lib.sh"

usage() {
  cat <<EOF
Usage: ${0##*/} TOKEN [--deep]

Checks a GitHub user/OAuth/PAT/GITHUB_TOKEN style token.

Default mode is lightweight: token, identity, organizations, and repository
discovery. Pass --deep to probe repository metadata, contents, Actions, issues,
pull requests, releases, and deployments for every discovered repository.

The token value and token abbreviation are never printed.
EOF
}

guess_token_type() {
  case "$GITHUB_AUTH_TOKEN" in
  github_pat_*) printf 'fine-grained personal access token' ;;
  ghp_*) printf 'classic personal access token' ;;
  gho_*) printf 'OAuth access token' ;;
  ghu_*) printf 'GitHub App user access token' ;;
  ghs_*) printf 'GitHub Actions or GitHub App installation token' ;;
  *) printf 'unknown GitHub token' ;;
  esac
}

check_user() {
  step "Read authenticated user"
  note "GET $API_BASE/user"

  if ! request "$API_BASE/user"; then
    hard_fail "request failed before GitHub returned a response"
    report "identity" "FAIL" "Authenticated user" "request failed before GitHub returned a response"
    return
  fi

  kv "HTTP" "$RESPONSE_STATUS"
  if ! api_succeeded; then
    local err
    err="$(error_summary)"
    hard_fail "authenticated user is not readable: $err"
    print_errors
    report "identity" "FAIL" "Authenticated user" "$err"
    return
  fi

  local login type scopes accepted_scopes expiration
  login="$(jq -r '.login // "unknown"' <<<"$RESPONSE_BODY")"
  type="$(jq -r '.type // "unknown"' <<<"$RESPONSE_BODY")"
  scopes="$(header_value "x-oauth-scopes")"
  accepted_scopes="$(header_value "x-accepted-oauth-scopes")"
  expiration="$(header_value "github-authentication-token-expiration")"

  ok "authenticated user is readable"
  kv "login" "$login"
  kv "type" "$type"
  report "identity" "OK" "Authenticated principal" "$login ($type)"

  if [[ -n $scopes ]]; then
    report "token" "OK" "OAuth scopes" "$scopes"
    report "token" "OK" "Detected token model" "classic/OAuth scope-bearing token"
  else
    report "token" "WARN" "OAuth scopes" "none returned; fine-grained/App/Actions tokens require endpoint probing"
  fi

  if [[ -n $accepted_scopes ]]; then
    report "token" "OK" "Accepted scopes for /user" "$accepted_scopes"
  fi

  if [[ -n $expiration ]]; then
    report "token" "OK" "Token expiration" "$expiration"
  fi

  return 0
}

check_rate_limit() {
  step "Read rate limit"
  note "GET $API_BASE/rate_limit"

  if ! request "$API_BASE/rate_limit"; then
    warn "request failed before GitHub returned a response"
    report "token" "WARN" "Rate limit" "request failed before GitHub returned a response"
    return
  fi

  kv "HTTP" "$RESPONSE_STATUS"
  if ! api_succeeded; then
    local err
    err="$(error_summary)"
    warn "rate limit is not readable: $err"
    print_errors
    report "token" "WARN" "Rate limit" "$err"
    return
  fi

  local limit remaining
  limit="$(jq -r '.resources.core.limit // "unknown"' <<<"$RESPONSE_BODY")"
  remaining="$(jq -r '.resources.core.remaining // "unknown"' <<<"$RESPONSE_BODY")"
  ok "rate limit is readable"
  kv "remaining" "$remaining/$limit"
  report "token" "OK" "Rate limit" "$remaining/$limit remaining"
}

discover_orgs() {
  step "Discover organizations"
  note "GET $API_BASE/user/orgs?per_page=100"

  local url="$API_BASE/user/orgs?per_page=100"
  local total=0 page=0

  while [[ -n $url ]]; do
    page=$((page + 1))
    if ! request "$url"; then
      warn "request failed before GitHub returned a response"
      report "orgs" "WARN" "Organization discovery" "request failed before GitHub returned a response"
      return
    fi

    kv "HTTP page $page" "$RESPONSE_STATUS"
    if ! api_succeeded; then
      local err
      err="$(error_summary)"
      warn "organizations are not readable: $err"
      print_errors
      report "orgs" "WARN" "Organization discovery" "$err"
      return
    fi

    local count
    count="$(jq -r '. | length' <<<"$RESPONSE_BODY")"
    total=$((total + count))

    while IFS= read -r login; do
      [[ -n $login ]] || continue
      record_org "$login"
    done < <(jq -r '.[].login // empty' <<<"$RESPONSE_BODY")

    url="$(awk -F'[<>]' '/rel="next"/ { print $2; exit }' <<<"$(header_value "link")")"
  done

  ok "organizations are readable"
  kv "organizations" "$total"
  report "orgs" "OK" "Organization discovery" "$total organization(s) across $page page(s)"
}

discover_repos() {
  step "Discover repositories"
  note "GET $API_BASE/user/repos?per_page=100&affiliation=owner,collaborator,organization_member"

  local url="$API_BASE/user/repos?per_page=100&affiliation=owner,collaborator,organization_member"
  local total=0 page=0

  while [[ -n $url ]]; do
    page=$((page + 1))
    if ! request "$url"; then
      warn "request failed before GitHub returned a response"
      report "repos" "WARN" "Repository discovery" "request failed before GitHub returned a response"
      return
    fi

    kv "HTTP page $page" "$RESPONSE_STATUS"
    if ! api_succeeded; then
      local err
      err="$(error_summary)"
      warn "repositories are not readable: $err"
      print_errors
      report "repos" "WARN" "Repository discovery" "$err"
      return
    fi

    local count
    count="$(jq -r '. | length' <<<"$RESPONSE_BODY")"
    total=$((total + count))

    while IFS=$'\t' read -r full_name visibility permissions; do
      [[ -n $full_name ]] || continue
      record_repo "$full_name" "$visibility" "$permissions"
    done < <(
      jq -r '
        .[] |
        [
          .full_name,
          (.visibility // (if .private then "private" else "public" end)),
          (
            .permissions // {} |
            to_entries |
            map(select(.value == true) | .key) |
            if length == 0 then "none returned" else join(", ") end
          )
        ] |
        @tsv
      ' <<<"$RESPONSE_BODY"
    )

    url="$(awk -F'[<>]' '/rel="next"/ { print $2; exit }' <<<"$(header_value "link")")"
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
  probe "contents" "Repository contents: $full_name" "$API_BASE/repos/$full_name/contents?per_page=1" "contents API is readable"
  probe "actions" "Actions workflows: $full_name" "$API_BASE/repos/$full_name/actions/workflows?per_page=1" "Actions workflows are readable" '"workflow items visible: " + ((.workflows // []) | length | tostring)'
  probe "actions" "Actions secrets metadata: $full_name" "$API_BASE/repos/$full_name/actions/secrets/public-key" "Actions secrets public key is readable"
  probe "actions" "Environments: $full_name" "$API_BASE/repos/$full_name/environments?per_page=1" "environments are readable" '"environment items visible: " + ((.environments // []) | length | tostring)'
  probe "issues" "Issues: $full_name" "$API_BASE/repos/$full_name/issues?per_page=1" "issues endpoint is readable" '"issue items visible: " + (length | tostring)'
  probe "issues" "Pull requests: $full_name" "$API_BASE/repos/$full_name/pulls?per_page=1" "pull requests endpoint is readable" '"pull request items visible: " + (length | tostring)'
  probe "releases" "Releases: $full_name" "$API_BASE/repos/$full_name/releases?per_page=1" "releases endpoint is readable" '"release items visible: " + (length | tostring)'
  probe "releases" "Deployments: $full_name" "$API_BASE/repos/$full_name/deployments?per_page=1" "deployments endpoint is readable" '"deployment items visible: " + (length | tostring)'
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

  GITHUB_AUTH_TOKEN="$1"
  local mode="${2:-}"
  if [[ -n $mode && $mode != "--deep" ]]; then
    die "unknown option: $mode"
  fi

  require_cmd curl
  require_cmd jq

  header "GitHub User Token Check"
  report "token" "OK" "Token prefix model" "$(guess_token_type)"
  if [[ $mode == "--deep" ]]; then
    report "token" "OK" "Probe mode" "deep"
  else
    report "token" "OK" "Probe mode" "lightweight"
  fi

  check_user
  check_rate_limit
  discover_orgs
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
