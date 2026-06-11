#!/usr/bin/env bash

set -euo pipefail

readonly DEFAULT_EXT_FILE=".vscode/extensions.json"
readonly DEFAULT_CODE_BIN="code"

usage() {
  cat <<EOF
Usage: ${0##*/} [EXTENSIONS_JSON] [CODE_BIN]

Install VS Code workspace recommended extensions.

Arguments:
  EXTENSIONS_JSON  Path to VS Code extensions.json (default: $DEFAULT_EXT_FILE)
  CODE_BIN         VS Code CLI binary to use (default: $DEFAULT_CODE_BIN)
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

  EXT_FILE="${1:-$DEFAULT_EXT_FILE}"
  CODE_BIN="${2:-$DEFAULT_CODE_BIN}"
}

resolve_ext_file() {
  case "$EXT_FILE" in
  /*) return ;;
  esac

  if [[ -f $EXT_FILE ]]; then
    return
  fi

  if [[ -n ${JUST_INVOCATION_DIRECTORY:-} &&
    -f "$JUST_INVOCATION_DIRECTORY/$EXT_FILE" ]]; then
    EXT_FILE="$JUST_INVOCATION_DIRECTORY/$EXT_FILE"
  fi
}

require_inputs() {
  [[ -f $EXT_FILE ]] ||
    die "$EXT_FILE not found."

  command -v "$CODE_BIN" >/dev/null 2>&1 ||
    die "$CODE_BIN not found in PATH."

  command -v jq >/dev/null 2>&1 ||
    die "jq not found in PATH."
}

strip_jsonc_comments() {
  awk '
    BEGIN {
      in_string = 0
      escaped = 0
      line_comment = 0
      block_comment = 0
    }
    {
      out = ""
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        n = substr($0, i + 1, 1)

        if (line_comment) {
          break
        }

        if (block_comment) {
          if (c == "*" && n == "/") {
            block_comment = 0
            i++
          }
          continue
        }

        if (in_string) {
          out = out c
          if (escaped) {
            escaped = 0
          } else if (c == "\\") {
            escaped = 1
          } else if (c == "\"") {
            in_string = 0
          }
          continue
        }

        if (c == "\"") {
          in_string = 1
          out = out c
          continue
        }

        if (c == "/" && n == "/") {
          line_comment = 1
          break
        }

        if (c == "/" && n == "*") {
          block_comment = 1
          i++
          continue
        }

        out = out c
      }
      print out
      line_comment = 0
    }
  '
}

read_recommendations() {
  strip_jsonc_comments <"$EXT_FILE" |
    jq -r '.recommendations // [] | .[] | select(type == "string")'
}

load_recommendations() {
  local output
  output=$(read_recommendations) ||
    die "failed to parse recommendations from $EXT_FILE."

  EXTENSIONS=()
  [[ -z $output ]] || mapfile -t EXTENSIONS <<<"$output"
}

install_extension() {
  local extension="$1"
  info "Installing: $extension"
  "$CODE_BIN" --install-extension "$extension" --force >/dev/null 2>&1 ||
    die "failed to install extension: $extension"
}

install_recommendations() {
  if ((${#EXTENSIONS[@]} == 0)); then
    info "No extensions found in recommendations."
    return
  fi

  local extension
  for extension in "${EXTENSIONS[@]}"; do
    install_extension "$extension"
  done

  info "All extensions installed successfully."
}

main() {
  parse_args "$@"
  resolve_ext_file
  require_inputs

  info "Parsing and installing VS Code extensions from $EXT_FILE..."
  load_recommendations
  install_recommendations
}

main "$@"
