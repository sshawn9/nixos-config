#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="${0##*/}"

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME <mode> <version> [CarlaUE4 args...]

Arguments:
  mode       docker or host
  version    CARLA image tag, e.g. 0.9.15, 0.9.16, 0.10.0

All remaining args are passed directly to CarlaUE4.sh.

Examples:
  $SCRIPT_NAME docker 0.9.15 -nosound
  $SCRIPT_NAME docker 0.9.16 -quality-level=Low -nosound
  $SCRIPT_NAME host 0.10.0 -RenderOffScreen -nosound
EOF
  exit 0
}

# --- Core functions ---

# Run any Docker container with full GPU and display passthrough
run_docker() {
  local image="$1"
  shift

  # Create a stub for xdg-user-dir (not available in most containers)
  local xdg_stub="/tmp/.xdg-user-dir-carla-stub"
  printf '#!/bin/sh\necho /tmp/${1:-Documents}\n' >"$xdg_stub"
  chmod +x "$xdg_stub"

  exec docker run \
    --rm \
    --network=host \
    --user="$(id -u):$(id -g)" \
    --device=nvidia.com/gpu=all \
    -e NVIDIA_DRIVER_CAPABILITIES=all \
    -e DISPLAY="$DISPLAY" \
    -e HOME=/tmp \
    -e XDG_RUNTIME_DIR=/tmp/runtime \
    -v "$xdg_stub":/usr/local/bin/xdg-user-dir:ro \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "$XAUTHORITY":/tmp/.Xauthority:ro \
    -e XAUTHORITY=/tmp/.Xauthority \
    -v /etc/localtime:/etc/localtime:ro \
    "$image" \
    "$@"
}

# Launch CarlaUE4 via Docker
carla_docker() {
  local version="$1"
  shift
  run_docker "carlasim/carla:$version" bash CarlaUE4.sh "$@"
}

# Launch CarlaUE4 on host
carla_host() {
  exec CarlaUE4.sh "$@"
}

# --- Main ---
main() {
  if [[ $# -lt 2 ]]; then
    usage
  fi

  local mode="$1" version="$2"
  shift 2

  case "$mode" in
  docker) carla_docker "$version" "$@" ;;
  host) carla_host "$@" ;;
  *)
    echo "Error: unknown mode '$mode'. Use 'docker' or 'host'." >&2
    exit 1
    ;;
  esac
}

main "$@"
