#!/usr/bin/env bash

set -euo pipefail

readonly API_BASE="https://api.github.com"

usage() {
  cat <<EOF
Usage: ${0##*/} TOKEN [--deep]

Dispatches GitHub credential checks by token prefix and API behavior.

Known token families:
  github_pat_*  fine-grained personal access token
  ghp_*         classic personal access token
  gho_*         OAuth access token
  ghu_*         GitHub App user access token
  ghs_*         GitHub Actions token or GitHub App installation token

Default mode is lightweight: token, identity, organizations, and repository
discovery. Pass --deep to probe repository metadata, contents, Actions, issues,
pull requests, releases, and deployments for every discovered repository.

The token is never printed or abbreviated.
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

request_status() {
  local token="$1"
  local url="$2"

  curl -sS \
    -o /dev/null \
    -w '%{http_code}' \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $token" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$url"
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

  local token="$1"
  local mode="${2:-}"
  if [[ -n $mode && $mode != "--deep" ]]; then
    die "unknown option: $mode"
  fi

  local script_dir
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

  local status
  status="$(request_status "$token" "$API_BASE/installation")" ||
    status="000"

  if [[ $status == 2* ]]; then
    exec bash "$script_dir/check-github-installation.sh" "$token" "$mode"
  fi

  case "$token" in
  github_pat_* | ghp_* | gho_* | ghu_* | ghs_*)
    exec bash "$script_dir/check-github-user.sh" "$token" "$mode"
    ;;
  *)
    exec bash "$script_dir/check-github-user.sh" "$token" "$mode"
    ;;
  esac
}

main "$@"
