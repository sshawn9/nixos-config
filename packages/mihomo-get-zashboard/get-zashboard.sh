#!/usr/bin/env bash

set -euo pipefail

FORCE=false

for arg in "$@"; do
  case "$arg" in
  --force)
    FORCE=true
    ;;
  esac
done

TARGET_DIR="/var/lib/mihomo"

if [ "$FORCE" = false ] && [ -f "${TARGET_DIR}/ui/index.html" ]; then
  echo "Zashboard already exists at ${TARGET_DIR}/ui/index.html. Use --force to overwrite."
  exit 0
fi

echo "Target directory: $TARGET_DIR"
echo "Downloading latest zashboard release..."

TMP_ZIP=$(mktemp)
trap 'rm -f "$TMP_ZIP"' EXIT

curl -fsSL -o "$TMP_ZIP" "https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip" ||
  {
    echo "Error: Download failed" >&2
    exit 1
  }
[ -s "$TMP_ZIP" ] ||
  {
    echo "Error: Downloaded file is empty" >&2
    exit 1
  }

echo "Extracting to ${TARGET_DIR}/ui folder..."

TMP_DIR=$(mktemp -d)
trap 'rm -f "$TMP_ZIP"; rm -rf "$TMP_DIR"' EXIT

unzip -q "$TMP_ZIP" -d "$TMP_DIR" ||
  {
    echo "Error: Extract failed" >&2
    exit 1
  }

rm -rf "${TARGET_DIR}/ui"
mv "${TMP_DIR}/dist" "${TARGET_DIR}/ui"

echo "Successfully extracted zashboard to ${TARGET_DIR}/ui"
