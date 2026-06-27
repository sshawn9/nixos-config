#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Usage: ${0##*/} TOKEN

Dispatches Cloudflare credential checks by token prefix:
  cfut_*  -> check-cloudflare-user.sh
  cfat_*  -> check-cloudflare-account.sh

The token is never printed or abbreviated. The scripts discover visible
Cloudflare accounts and zones automatically, then probe every discovered target.
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

main() {
  case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  esac

  (($# == 1)) || die "usage: ${0##*/} TOKEN"

  local token="$1"
  local script_dir
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

  case "$token" in
  cfut_*)
    exec bash "$script_dir/check-cloudflare-user.sh" "$token"
    ;;
  cfat_*)
    exec bash "$script_dir/check-cloudflare-account.sh" "$token"
    ;;
  *)
    die "unsupported Cloudflare token prefix. Expected cfut_* or cfat_*."
    ;;
  esac
}

main "$@"
