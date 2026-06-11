#!/usr/bin/env bash

# Interactive wizard for creating distrobox containers.

set -euo pipefail

readonly PROGNAME="${0##*/}"
readonly DIM=$'\033[0;90m'
readonly GREEN=$'\033[1;32m'
readonly CYAN=$'\033[0;36m'
readonly RED=$'\033[1;31m'
readonly YELLOW=$'\033[1;33m'
readonly GRAY=$'\033[0;37m'
readonly RST=$'\033[0m'

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------
die() {
  printf '❌ %s%s%s\n' "$RED" "$1" "$RST" >&2
  exit "${2:-1}"
}

info() {
  printf '💡 %s\n' "$1" >&2
}

success() {
  printf '✅ %s\n' "$1" >&2
}

warn() {
  printf '⚠️  %s\n' "$1" >&2
}

section() {
  printf '\n%s── %s ──%s\n' "$YELLOW" "$1" "$RST" >&2
}

banner() {
  cat >&2 <<'EOF'

📦 ╔════════════════════════════════════╗
   ║       🚀 Create Distrobox          ║
   ╚════════════════════════════════════╝

EOF
}

usage() {
  cat <<EOF
Usage: $PROGNAME [IMAGE] [NAME]

Interactive wizard for creating distrobox containers.
All options are configured interactively.

Arguments:
  IMAGE   Container image (interactive if omitted)
  NAME    Container name  (interactive if omitted)

Options:
  -h, --help   Show this help message

Environment:
  DBX_CONTAINER_MANAGER   Preferred container backend (podman/docker)
  CONTAINER_MANAGER       Fallback backend variable
EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Interactive primitives
# ---------------------------------------------------------------------------
# confirm PROMPT [DEFAULT=n]
confirm() {
  local prompt="$1" default="${2:-n}" reply hint
  if [[ $default == "y" ]]; then
    hint="Y/n, default: yes"
  else
    hint="y/N, default: no"
  fi
  local formatted
  printf -v formatted '❓ %b (%s): ' "$prompt" "$hint"
  while true; do
    read -rp "$formatted" reply || die "unexpected EOF"
    reply="${reply:-$default}"
    case "$reply" in
    [Yy]) return 0 ;;
    [Nn]) return 1 ;;
    *) printf '  ↳ Please answer y or n.\n' >&2 ;;
    esac
  done
}

# prompt DESCRIPTION [DEFAULT]
prompt() {
  local msg="$1" default="${2:-}" reply
  printf '📝 %b\n' "$msg" >&2
  if [[ -n $default ]]; then
    read -rp "✏️  [default: $default]: " reply || die "unexpected EOF"
  else
    read -rp "✏️  : " reply || die "unexpected EOF"
  fi
  printf '%s' "${reply:-$default}"
}

# menu DEFAULT OPTION1 OPTION2 ...
menu() {
  local default="$1"
  shift
  local -a options=("$@")
  local total=${#options[@]}

  local i
  for ((i = 0; i < total; i++)); do
    local num=$((i + 1))
    if ((num == default)); then
      printf '%s  %d) %s  ← default%s\n' \
        "$GREEN" "$num" "${options[i]}" "$RST" >&2
    else
      printf '  %d) %s\n' "$num" "${options[i]}" >&2
    fi
  done

  local reply
  while true; do
    printf '\n' >&2
    read -rp "📌 Enter number [default: $default]: " reply ||
      die "unexpected EOF"
    reply="${reply:-$default}"
    if [[ $reply =~ ^[0-9]+$ ]] &&
      ((reply >= 1 && reply <= total)); then
      printf '%d' "$reply"
      return
    fi
    printf '  ↳ Invalid, enter 1-%d.\n' "$total" >&2
  done
}

# ---------------------------------------------------------------------------
# Backend detection
# ---------------------------------------------------------------------------
detect_backend() {
  local backend="${DBX_CONTAINER_MANAGER:-${CONTAINER_MANAGER:-}}"
  if [[ -n $backend ]]; then
    printf '%s' "$backend"
    return
  fi
  local candidate
  for candidate in podman docker; do
    if command -v "$candidate" &>/dev/null; then
      printf '%s' "$candidate"
      return
    fi
  done
  die "no container manager found (podman or docker required)"
}

# ---------------------------------------------------------------------------
# Image selection
# ---------------------------------------------------------------------------
select_image() {
  local backend="$1" preselected="${2:-}"

  if [[ -n $preselected ]]; then
    printf '%s' "$preselected"
    return
  fi

  section "📦 Image Selection"
  printf '%s→ --image <IMAGE>%s\n\n' "$DIM" "$RST" >&2

  local -a images
  mapfile -t images < <(
    "$backend" images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null |
      grep -v '<none>' | sort -u || true
  )

  if [[ ${#images[@]} -eq 0 ]]; then
    local img
    img=$(prompt "No local images found.\n   Enter image name (e.g. ubuntu:22.04)") ||
      exit 1
    [[ -n $img ]] || die "image name is required"
    printf '%s' "$img"
    return
  fi

  printf '🐳 Select from local %s cache:\n\n' "$backend" >&2

  local i
  for ((i = 0; i < ${#images[@]}; i++)); do
    printf '  %d) %s\n' "$((i + 1))" "${images[i]}" >&2
  done
  printf '  %d) ✍️  Enter manually\n' "$((${#images[@]} + 1))" >&2

  local total=$((${#images[@]} + 1))
  local reply
  while true; do
    printf '\n' >&2
    read -rp "📌 Enter number: " reply || die "unexpected EOF"
    if [[ ! $reply =~ ^[0-9]+$ ]] ||
      ((reply < 1 || reply > total)); then
      printf '  ↳ Invalid, enter 1-%d.\n' "$total" >&2
      continue
    fi
    if ((reply == total)); then
      printf '\n' >&2
      local custom
      custom=$(prompt "Enter image name (e.g. ubuntu:22.04)") ||
        exit 1
      [[ -n $custom ]] || die "image name is required"
      printf '%s' "$custom"
      return
    fi
    printf '%s' "${images[reply - 1]}"
    return
  done
}

# ---------------------------------------------------------------------------
# Container name
# ---------------------------------------------------------------------------
read_container_name() {
  local preselected="${1:-}"

  if [[ -n $preselected ]]; then
    printf '%s' "$preselected"
    return
  fi

  section "📛 Container Name"
  printf '%s→ --name <NAME>%s\n\n' "$DIM" "$RST" >&2

  local -a existing
  mapfile -t existing < <(
    distrobox list --no-color 2>/dev/null |
      tail -n +2 | awk '{print $3}' | sort || true
  )
  if [[ ${#existing[@]} -gt 0 ]]; then
    printf '📋 Existing boxes:\n\n' >&2
    local c
    for c in "${existing[@]}"; do
      printf '  · %s%s%s\n' "$GRAY" "$c" "$RST" >&2
    done
    printf '\n' >&2
  fi

  local name
  name=$(prompt "Container name (e.g. my-box)\n   Leave empty to derive from image")

  if [[ -n $name && ! $name =~ ^[a-zA-Z0-9_-]+$ ]]; then
    die "invalid name '$name': only alphanumeric, dashes, and underscores allowed"
  fi

  printf '%s' "$name"
}

# ---------------------------------------------------------------------------
# Init system
# ---------------------------------------------------------------------------
select_init() {
  local -n _opts=$1

  section "⚙️  Init System"
  printf '%s→ --init%s\n\n' "$DIM" "$RST" >&2

  printf 'Enable init system (systemd) inside the box.\n' >&2
  printf 'Required for services, timers, and daemons.\n\n' >&2

  if confirm "Enable init system?" "y"; then
    _opts+=(--init)
    info "Init → enabled"
  else
    info "Init → disabled"
  fi
}

# ---------------------------------------------------------------------------
# Home directory
# ---------------------------------------------------------------------------
select_home() {
  local -n _opts=$1

  section "🏠 Home Directory"
  printf '%s→ --home <PATH>%s\n\n' "$DIM" "$RST" >&2

  printf 'Custom home directory for the box.\n' >&2
  printf 'Default: share host home directory.\n\n' >&2

  local home_dir
  home_dir=$(prompt "Custom home path\n   e.g. ~/.local/share/distrobox/my-box\n   Press Enter to share host home")
  if [[ -n $home_dir ]]; then
    _opts+=(--home "$home_dir")
    info "Home → $home_dir"
  else
    info "Home → shared with host"
  fi
}

# ---------------------------------------------------------------------------
# Pull policy
# ---------------------------------------------------------------------------
select_pull() {
  local -n _opts=$1

  section "📥 Pull Policy"
  printf '%s→ --pull%s\n\n' "$DIM" "$RST" >&2

  printf 'Always pull the latest image before creating.\n\n' >&2

  if confirm "Always pull latest image?" "n"; then
    _opts+=(--pull)
    info "Pull → always"
  else
    info "Pull → use cached"
  fi
}

# ---------------------------------------------------------------------------
# NVIDIA GPU
# ---------------------------------------------------------------------------
select_nvidia() {
  local -n _opts=$1

  command -v nvidia-smi &>/dev/null || return

  section "🎮 NVIDIA GPU"
  printf '%s→ --nvidia%s\n\n' "$DIM" "$RST" >&2

  printf 'NVIDIA GPU detected.\n' >&2
  printf 'Pass through GPU to container.\n\n' >&2

  if confirm "Enable NVIDIA GPU passthrough?" "y"; then
    _opts+=(--nvidia)
    info "GPU → NVIDIA enabled"
  else
    info "GPU → disabled"
  fi
}

# ---------------------------------------------------------------------------
# Build command
# ---------------------------------------------------------------------------
build_cmd() {
  local backend="$1" image="$2" name="$3"
  local -n _extra_opts=$4

  CMD_ARRAY=(distrobox create --image "$image")

  if [[ -n $name ]]; then
    CMD_ARRAY+=(--name "$name")
  fi

  CMD_ARRAY+=("${_extra_opts[@]}")
}

# ---------------------------------------------------------------------------
# Review and execute
# ---------------------------------------------------------------------------
print_command() {
  local -a lines=()
  local i=2 # skip "distrobox" "create"
  while ((i < ${#CMD_ARRAY[@]})); do
    local arg="${CMD_ARRAY[i]}"
    case "$arg" in
    --image | --name | --home | --volume | --additional-packages)
      if ((i + 1 < ${#CMD_ARRAY[@]})); then
        lines+=("$arg ${CMD_ARRAY[i + 1]}")
        ((i += 2))
      else
        lines+=("$arg")
        ((i++))
      fi
      ;;
    *)
      lines+=("$arg")
      ((i++))
      ;;
    esac
  done

  printf '%sdistrobox create \\\n' "$CYAN" >&2
  for ((j = 0; j < ${#lines[@]}; j++)); do
    if ((j == ${#lines[@]} - 1)); then
      printf '  %s%s\n' "${lines[j]}" "$RST" >&2
    else
      printf '  %s \\\n' "${lines[j]}" >&2
    fi
  done
}

confirm_and_run() {
  section "🔍 Review"
  print_command

  printf '\n' >&2
  if ! confirm "🚀 Execute this command?" "y"; then
    printf '\n' >&2
    warn "Aborted."
    exit 0
  fi

  printf '\n' >&2
  info "Creating distrobox..."
  "${CMD_ARRAY[@]}" || die "failed to create distrobox"
}

post_create() {
  local name="$1" image="$2"
  local display_name="${name:-$(basename "${image%%:*}")}"

  printf '\n' >&2
  success "Distrobox '$display_name' created successfully."

  printf '\n' >&2
  if confirm "🚪 Enter '$display_name' now?" "y"; then
    exec distrobox enter "$display_name"
  else
    printf '\n' >&2
    info "Enter later: distrobox enter $display_name"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    usage
  fi

  local image_arg="${1:-}" name_arg="${2:-}"

  banner

  local backend
  backend=$(detect_backend)
  info "Backend → $backend"

  local image
  image=$(select_image "$backend" "$image_arg")
  info "Image → $image"

  local name
  name=$(read_container_name "$name_arg")
  if [[ -n $name ]]; then
    info "Name → $name"
  else
    info "Name → (derived from image)"
  fi

  local -a opts=()
  select_init opts
  select_home opts
  select_pull opts
  select_nvidia opts

  build_cmd "$backend" "$image" "$name" opts
  confirm_and_run
  post_create "$name" "$image"
}

main "$@"
