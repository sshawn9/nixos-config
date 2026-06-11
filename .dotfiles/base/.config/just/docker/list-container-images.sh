#!/usr/bin/env bash
# List container images across Docker and Podman rootful/rootless stores.

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

readonly CURRENT_UID="$(id -u)"
readonly TABLE_FMT='table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}'

# Store registry — each entry: "id|icon|label|description|color_name|engine"
readonly STORES=(
  "docker-rootful|🐋|Docker Rootful|rootful daemon via /var/run/docker.sock|CYAN|docker"
  "docker-rootless|🐋|Docker Rootless|rootless daemon via /run/user/${CURRENT_UID}/docker.sock|CYAN|docker"
  "podman-rootless|🦭 |Podman Rootless|user-level storage (~/.local/share/containers/)|GREEN|podman"
  "podman-rootful|🦭 |Podman Rootful|system-level storage (/var/lib/containers/)|GREEN|podman"
)

# ---------------------------------------------------------------------------
# Terminal colors (disabled when piped)
# ---------------------------------------------------------------------------

setup_colors() {
  if [[ -t 1 ]]; then
    readonly BOLD=$'\033[1m' DIM=$'\033[0;90m' RST=$'\033[0m'
    readonly CYAN=$'\033[0;36m' GREEN=$'\033[1;32m' YELLOW=$'\033[1;33m'
  else
    readonly BOLD="" DIM="" RST="" CYAN="" GREEN="" YELLOW=""
  fi
}

# ---------------------------------------------------------------------------
# Output primitives
# ---------------------------------------------------------------------------

warn() { printf '⚠️  %s\n' "$1" >&2; }
dim() { printf '   %s%s%s\n' "$DIM" "$1" "$RST"; }

print_header() {
  local icon="$1" color="$2" label="$3" desc="$4"
  printf '%s%s %s%s%s  —  %s\n' "$BOLD" "$icon" "$color" "$label" "$RST" "$desc"
}

print_table() {
  local count="$1" output="$2"
  printf '   🖼️  %s%d%s image(s)\n\n' "$YELLOW" "$count" "$RST"
  printf '%s\n' "$output"
}

# ---------------------------------------------------------------------------
# Store operations (each function does exactly one thing)
# ---------------------------------------------------------------------------

# Map store id → command array. Sets STORE_CMD.
resolve_cmd() {
  case "$1" in
  docker-rootful) STORE_CMD=(docker) ;;
  docker-rootless) STORE_CMD=(docker --host "unix:///run/user/${CURRENT_UID}/docker.sock") ;;
  podman-rootless) STORE_CMD=(podman) ;;
  podman-rootful) STORE_CMD=(sudo podman) ;;
  esac
}

# Check store prerequisites. Returns 0 if met, 1 with SKIP_REASON set.
check_prereqs() {
  local id="$1" engine="$2"
  SKIP_REASON=""

  if ! command -v "$engine" &>/dev/null; then
    SKIP_REASON="$engine is not installed"
    return 1
  fi

  if [[ $id == "docker-rootless" && ! -S "/run/user/${CURRENT_UID}/docker.sock" ]]; then
    SKIP_REASON="rootless daemon not running"
    return 1
  fi
}

# Fetch images. Sets FETCH_OUTPUT and FETCH_COUNT.
# Lets stderr through for sudo commands (password prompt); suppresses otherwise.
fetch_images() {
  local -a cmd=("$@")
  FETCH_OUTPUT="" FETCH_COUNT=0

  if [[ ${cmd[0]} == "sudo" ]] && [[ -t 0 ]]; then
    # Interactive: let sudo prompt for password via stderr
    FETCH_OUTPUT=$("${cmd[@]}" images --all --format "$TABLE_FMT") || return 1
  else
    FETCH_OUTPUT=$("${cmd[@]}" images --all --format "$TABLE_FMT" 2>/dev/null) || return 1
  fi

  FETCH_COUNT=$(printf '%s\n' "$FETCH_OUTPUT" | tail -n +2 | grep -c . || true)
}

# ---------------------------------------------------------------------------
# Store renderer — orchestrates: header → prereqs → fetch → display
# ---------------------------------------------------------------------------

render_store() {
  local id icon label desc color_name engine
  IFS='|' read -r id icon label desc color_name engine <<<"$1"

  local color="${!color_name}"
  print_header "$icon" "$color" "$label" "$desc"

  # 1. prerequisites
  local SKIP_REASON
  if ! check_prereqs "$id" "$engine"; then
    dim "⏭️  $SKIP_REASON"
    return 0
  fi

  # 2. fetch
  local -a STORE_CMD
  resolve_cmd "$id"
  dim "$ ${STORE_CMD[*]} images --all"

  local FETCH_OUTPUT FETCH_COUNT
  if ! fetch_images "${STORE_CMD[@]}"; then
    dim "⏭️  not available (daemon not reachable or sudo required)"
    return 0
  fi

  # 3. display
  if ((FETCH_COUNT == 0)); then
    dim "📭 no images"
  else
    print_table "$FETCH_COUNT" "$FETCH_OUTPUT"
  fi
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

main() {
  setup_colors

  local first=true
  for record in "${STORES[@]}"; do
    $first || echo
    first=false
    render_store "$record"
  done

  if ! command -v docker &>/dev/null && ! command -v podman &>/dev/null; then
    echo
    warn "No container runtimes found. Install docker or podman."
  fi
}

main "$@"
