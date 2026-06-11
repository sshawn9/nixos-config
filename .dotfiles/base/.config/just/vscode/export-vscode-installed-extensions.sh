#!/usr/bin/env bash

set -euo pipefail

readonly DEFAULT_OUT_FILE="extensions.installed.json"
readonly DEFAULT_CODE_BIN="code"

usage() {
  cat <<EOF
Usage: ${0##*/} [OUTPUT_JSON] [CODE_BIN]

Export currently installed VS Code extensions as workspace recommendations.

Arguments:
  OUTPUT_JSON  Path to write extensions JSON (default: $DEFAULT_OUT_FILE)
  CODE_BIN     VS Code CLI binary to use (default: $DEFAULT_CODE_BIN)
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

info() {
  echo "$*"
}

parse_args() {
  case "${1:-}" in
  -h | --help)
    usage
    exit 0
    ;;
  esac

  OUT_FILE="${1:-$DEFAULT_OUT_FILE}"
  CODE_BIN="${2:-$DEFAULT_CODE_BIN}"
}

resolve_out_file() {
  case "$OUT_FILE" in
  /*) return ;;
  esac

  if [[ -n "${JUST_INVOCATION_DIRECTORY:-}" ]]; then
    OUT_FILE="$JUST_INVOCATION_DIRECTORY/$OUT_FILE"
  fi
}

require_tools() {
  command -v "$CODE_BIN" >/dev/null 2>&1 ||
    die "$CODE_BIN not found in PATH."

  command -v jq >/dev/null 2>&1 ||
    die "jq not found in PATH."

  command -v sort >/dev/null 2>&1 ||
    die "sort not found in PATH."
}

prepare_output_dir() {
  local out_dir
  out_dir="$(dirname "$OUT_FILE")"

  mkdir -p "$out_dir" ||
    die "failed to create output directory: $out_dir"
}

read_installed_extensions() {
  "$CODE_BIN" --list-extensions |
    sed '/^[[:space:]]*$/d' |
    LC_ALL=C sort -u
}

load_installed_extensions() {
  local output
  output="$(read_installed_extensions)" ||
    die "failed to list installed VS Code extensions."

  EXTENSIONS=()
  [[ -z "$output" ]] || mapfile -t EXTENSIONS <<<"$output"
}

write_extensions_json() {
  if ((${#EXTENSIONS[@]} == 0)); then
    jq -n '{recommendations: []}' >"$OUT_FILE"
    return
  fi

  printf '%s\n' "${EXTENSIONS[@]}" |
    jq -Rn '{recommendations: [inputs]}' >"$OUT_FILE"
}

export_extensions() {
  info "Exporting ${#EXTENSIONS[@]} VS Code extensions to $OUT_FILE..."
  write_extensions_json ||
    die "failed to write extensions JSON: $OUT_FILE"
  info "Extensions exported successfully."
}

main() {
  parse_args "$@"
  resolve_out_file
  require_tools
  prepare_output_dir
  load_installed_extensions
  export_extensions
}

main "$@"
