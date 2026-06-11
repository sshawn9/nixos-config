#!/usr/bin/env bash
# Pull the latest version of every tagged image across all 4 independent stores.
# Images without a tag (dangling / ID-only) or with tags that don't exist
# on a remote registry are silently skipped.

set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

readonly CURRENT_UID="$(id -u)"

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
    readonly RED=$'\033[0;31m'
  else
    readonly BOLD="" DIM="" RST="" CYAN="" GREEN="" YELLOW="" RED=""
  fi
}

# ---------------------------------------------------------------------------
# Output primitives
# ---------------------------------------------------------------------------

warn() { printf '⚠️  %s\n' "$1" >&2; }
dim() { printf '   %s%s%s\n' "$DIM" "$1" "$RST"; }
info() { printf '   %s\n' "$1"; }

print_header() {
  local icon="$1" color="$2" label="$3" desc="$4"
  printf '%s%s %s%s%s  —  %s\n' "$BOLD" "$icon" "$color" "$label" "$RST" "$desc"
}

# ---------------------------------------------------------------------------
# Store operations
# ---------------------------------------------------------------------------

resolve_cmd() {
  case "$1" in
  docker-rootful) STORE_CMD=(docker) ;;
  docker-rootless) STORE_CMD=(docker --host "unix:///run/user/${CURRENT_UID}/docker.sock") ;;
  podman-rootless) STORE_CMD=(podman) ;;
  podman-rootful) STORE_CMD=(sudo podman) ;;
  esac
}

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

# Collect pullable image references (repository:tag).
# Skips: <none> repo, <none> tag, localhost-only references.
collect_pullable_images() {
  local -a cmd=("$@")
  PULL_IMAGES=()

  local output
  if [[ ${cmd[0]} == "sudo" ]] && [[ -t 0 ]]; then
    output=$("${cmd[@]}" images --format '{{.Repository}}:{{.Tag}}' 2>&1) || return 1
  else
    output=$("${cmd[@]}" images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null) || return 1
  fi

  while IFS= read -r ref; do
    # Skip images without repo or tag
    [[ $ref == *"<none>"* ]] && continue
    # Skip empty lines
    [[ -z $ref ]] && continue
    PULL_IMAGES+=("$ref")
  done <<<"$output"

  # Deduplicate (same image can appear multiple times with different IDs)
  if ((${#PULL_IMAGES[@]} > 0)); then
    local -A seen=()
    local -a unique=()
    for ref in "${PULL_IMAGES[@]}"; do
      if [[ -z ${seen[$ref]+x} ]]; then
        seen[$ref]=1
        unique+=("$ref")
      fi
    done
    PULL_IMAGES=("${unique[@]}")
  fi
}

# ---------------------------------------------------------------------------
# Store updater — orchestrates: header → prereqs → collect → pull
# ---------------------------------------------------------------------------
update_store() {
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

  # 2. resolve command
  local -a STORE_CMD
  resolve_cmd "$id"

  # 3. collect pullable images
  local -a PULL_IMAGES
  if ! collect_pullable_images "${STORE_CMD[@]}"; then
    dim "⏭️  not available (daemon not reachable or sudo required)"
    return 0
  fi

  if ((${#PULL_IMAGES[@]} == 0)); then
    dim "📭 no pullable images"
    return 0
  fi

  info "🖼️  ${YELLOW}${#PULL_IMAGES[@]}${RST} image(s) to update"
  echo

  # 4. pull each image
  local succeeded=0 skipped=0
  for ref in "${PULL_IMAGES[@]}"; do
    printf '\n   ⏳ pulling %s%s%s\n' "$BOLD" "$ref" "$RST"
    if "${STORE_CMD[@]}" pull "$ref"; then
      ((++succeeded))
    else
      printf '   %sskipped%s (not available on remote)\n' "$DIM" "$RST"
      ((++skipped))
    fi
  done

  echo
  info "📊 ${GREEN}${succeeded}${RST} pulled, ${DIM}${skipped}${RST} skipped"
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
    update_store "$record"
  done

  if ! command -v docker &>/dev/null && ! command -v podman &>/dev/null; then
    echo
    warn "No container runtimes found. Install docker or podman."
  fi
}

main "$@"
