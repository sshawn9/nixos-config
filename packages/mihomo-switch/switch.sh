#!/usr/bin/env bash

set -euo pipefail

readonly TARGET_CONFIG="/var/lib/mihomo/config.yaml"
TMP_FILE=""

usage() {
  cat <<'EOF'
Usage: mihomo-switch [OPTIONS] URL

Download and apply a mihomo configuration file.

Options:
  --init         Initialize mode: skip download if config already exists
  --no-restart   Do not restart mihomo after updating config
  -h, --help     Show this help message

Arguments:
  URL            Config download URL
EOF
}

parse_args() {
  INIT=false
  NO_RESTART=false
  POSITIONAL_ARGS=()

  for arg in "$@"; do
    case "$arg" in
    --init)
      INIT=true
      ;;
    --no-restart)
      NO_RESTART=true
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      POSITIONAL_ARGS+=("$arg")
      ;;
    esac
  done

  URL="${POSITIONAL_ARGS[0]:-}"
  if [[ -z ${URL:-} ]]; then
    echo "Missing config URL. Pass URL explicitly." >&2
    exit 1
  fi

  read -ra RESTART_CMD <<<"${MIHOMO_RESTART_CMD:-systemctl restart mihomo}"
}

check_root() {
  if ((EUID != 0)); then
    echo "Permission denied. Please run as root (sudo)." >&2
    exit 1
  fi
}

download_config() {
  local tmp_file="$1"

  echo "Start downloading: $URL"
  curl -fsSL -o "$tmp_file" "$URL" || {
    echo "Download failed" >&2
    exit 1
  }
  [[ -s $tmp_file ]] || {
    echo "Downloaded file is empty" >&2
    exit 1
  }
}

backup_config() {
  if [[ -f $TARGET_CONFIG ]]; then
    local timestamp bak_file
    timestamp=$(date +"%Y%m%d-%H%M%S")
    bak_file="${TARGET_CONFIG}.${timestamp}.bak"
    echo "Backup old config to: $bak_file"
    cp "$TARGET_CONFIG" "$bak_file"
  fi
}

install_config() {
  local tmp_file="$1"

  backup_config
  install -m 644 "$tmp_file" "$TARGET_CONFIG"
  echo "Updated config successfully at $TARGET_CONFIG"
}

restart_service() {
  if [[ $NO_RESTART == true ]]; then
    echo "Skipping service restart (--no-restart specified)."
    return
  fi

  echo "Restarting mihomo service..."
  "${RESTART_CMD[@]}" || {
    echo "Service restart failure, please check logs." >&2
    exit 1
  }
}

cleanup() {
  if [[ -n ${TMP_FILE:-} ]]; then
    rm -f "$TMP_FILE"
  fi
}

main() {
  parse_args "$@"
  check_root

  if [[ $INIT == true && -f $TARGET_CONFIG ]]; then
    echo "Config already exists at $TARGET_CONFIG, skipping download (--init)."
    restart_service
    return
  fi

  TMP_FILE=$(mktemp)
  trap cleanup EXIT

  mkdir -p "$(dirname "$TARGET_CONFIG")"
  download_config "$TMP_FILE"
  install_config "$TMP_FILE"
  restart_service
}

main "$@"
