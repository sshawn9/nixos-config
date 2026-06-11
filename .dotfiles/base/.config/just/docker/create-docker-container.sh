#!/usr/bin/env bash

# Interactive wizard for creating persistent Docker containers.

set -euo pipefail

readonly PROGNAME="${0##*/}"
readonly DEFAULT_CMD="bash"
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

🐳 ╔════════════════════════════════════╗
   ║    🚀 Create Docker Container      ║
   ╚════════════════════════════════════╝

EOF
}

usage() {
  cat <<EOF
Usage: $PROGNAME [IMAGE] [NAME] [CMD]

Interactive wizard for creating Docker containers.
All options are configured interactively.

Arguments:
  IMAGE   Container image  (interactive if omitted)
  NAME    Container name   (interactive if omitted)
  CMD     Startup command  (default: $DEFAULT_CMD)

Options:
  -h, --help   Show this help message
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
# Image selection
# ---------------------------------------------------------------------------
select_image() {
  local preselected="${1:-}"

  if [[ -n $preselected ]]; then
    printf '%s' "$preselected"
    return
  fi

  section "📦 Image Selection"
  printf '%s→ docker run <IMAGE>%s\n\n' "$DIM" "$RST" >&2

  local -a images
  mapfile -t images < <(
    docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null |
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

  printf '🐳 Select from local Docker cache:\n\n' >&2

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

  # Show existing containers to avoid name conflicts
  local -a existing
  mapfile -t existing < <(
    docker ps -a --format '{{.Names}}' 2>/dev/null |
      sort || true
  )
  if [[ ${#existing[@]} -gt 0 ]]; then
    printf '📋 Existing containers:\n\n' >&2
    local c
    for c in "${existing[@]}"; do
      printf '  · %s%s%s\n' "$GRAY" "$c" "$RST" >&2
    done
    printf '\n' >&2
  fi

  local name
  name=$(prompt "Container name (e.g. my-container)\n   Leave empty for auto-generated name")

  if [[ -n $name &&
    ! $name =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
    die "invalid name '$name': alphanumeric, dash, underscore, dot only"
  fi

  printf '%s' "$name"
}

# ---------------------------------------------------------------------------
# Startup command
# ---------------------------------------------------------------------------
read_command() {
  local preselected="${1:-}"

  if [[ -n $preselected ]]; then
    printf '%s' "$preselected"
    return
  fi

  section "⚡ Startup Command"
  printf '%s→ docker run <IMAGE> [CMD]%s\n\n' "$DIM" "$RST" >&2

  printf '📝 Startup command\n   Enter a space to use image default CMD\n' >&2
  local reply
  IFS= read -rp "✏️  [default: bash]: " reply || die "unexpected EOF"
  reply="${reply:-bash}"
  # Whitespace-only input → empty string → image default CMD
  local trimmed="${reply// /}"
  if [[ -z $trimmed ]]; then
    printf ''
  else
    printf '%s' "$reply"
  fi
}

# ---------------------------------------------------------------------------
# Restart policy
# ---------------------------------------------------------------------------
select_restart() {
  local -n _opts=$1

  section "🔄 Restart Policy"
  printf '%s→ --restart=<POLICY>%s\n\n' "$DIM" "$RST" >&2

  local restart_idx
  restart_idx=$(menu 1 \
    "always (recommended)" \
    "unless-stopped" \
    "on-failure" \
    "no")
  local -a restart_map=(always unless-stopped on-failure no)
  local restart="${restart_map[restart_idx - 1]}"
  _opts+=(--restart="$restart")
  info "Restart → $restart"
}

# ---------------------------------------------------------------------------
# Privileged mode
# ---------------------------------------------------------------------------
select_privileged() {
  local -n _opts=$1

  section "🔓 Privileged Mode"
  printf '%s→ --privileged%s\n\n' "$DIM" "$RST" >&2

  printf 'Grant full host device access.\n' >&2
  printf 'Required for hardware interaction,\n' >&2
  printf 'GPU compute, and device passthrough.\n\n' >&2

  if confirm "Enable privileged mode?" "y"; then
    _opts+=(--privileged)
    info "Privileged → yes"
  else
    info "Privileged → no"
  fi
}

# ---------------------------------------------------------------------------
# IPC namespace
# ---------------------------------------------------------------------------
select_ipc() {
  local -n _opts=$1

  section "🔗 IPC Namespace"
  printf '%s→ --ipc=host%s\n\n' "$DIM" "$RST" >&2

  printf 'Share host IPC namespace.\n' >&2
  printf 'Required for shared memory between\n' >&2
  printf 'container and host processes.\n\n' >&2

  if confirm "Share host IPC?" "y"; then
    _opts+=(--ipc=host)
    info "IPC → host"
  else
    info "IPC → isolated"
  fi
}

# ---------------------------------------------------------------------------
# Network mode
# ---------------------------------------------------------------------------
select_network() {
  local -n _opts=$1

  section "🌐 Network Mode"
  printf '%s→ --network=<MODE>%s\n\n' "$DIM" "$RST" >&2

  local net_idx
  net_idx=$(menu 1 \
    "host (recommended)" \
    "bridge" \
    "none")
  local -a net_map=(host bridge none)
  local network="${net_map[net_idx - 1]}"
  _opts+=(--network="$network")
  info "Network → $network"
}

# ---------------------------------------------------------------------------
# GPU passthrough
# ---------------------------------------------------------------------------
select_gpu() {
  local -n _opts=$1

  command -v nvidia-smi &>/dev/null || return

  section "🎮 GPU Passthrough"
  printf '%s→ --device=nvidia.com/gpu=all, -e NVIDIA_DRIVER_CAPABILITIES=all%s\n\n' "$DIM" "$RST" >&2

  printf 'NVIDIA GPU detected.\n' >&2
  printf 'Pass through all GPUs to container.\n\n' >&2

  if confirm "Enable GPU passthrough?" "y"; then
    _opts+=(--device=nvidia.com/gpu=all)
    _opts+=(-e NVIDIA_DRIVER_CAPABILITIES=all)
    info "GPU → NVIDIA enabled"
  else
    info "GPU → disabled"
  fi
}

# ---------------------------------------------------------------------------
# X11 forwarding
# ---------------------------------------------------------------------------
select_x11() {
  local -n _opts=$1

  [[ -z ${DISPLAY:-} ]] && return

  section "🖥️  X11 Forwarding"
  printf '%s→ -e DISPLAY=$DISPLAY, -v /tmp/.X11-unix:/tmp/.X11-unix:rw%s\n\n' "$DIM" "$RST" >&2

  printf 'Forward X11 display to container.\n' >&2
  printf 'Current DISPLAY=%s\n\n' "$DISPLAY" >&2

  if confirm "Enable X11 forwarding?" "y"; then
    _opts+=(-e "DISPLAY=$DISPLAY")
    _opts+=(-v /tmp/.X11-unix:/tmp/.X11-unix:rw)
    info "X11 → enabled"
  else
    info "X11 → disabled"
  fi
}

# ---------------------------------------------------------------------------
# Timezone
# ---------------------------------------------------------------------------
select_timezone() {
  local -n _opts=$1

  section "🕐 Timezone"
  printf '%s→ -v /etc/localtime:/etc/localtime:ro%s\n\n' "$DIM" "$RST" >&2

  printf 'Sync container timezone with host.\n\n' >&2

  if confirm "Sync timezone?" "y"; then
    _opts+=(-v /etc/localtime:/etc/localtime:ro)
    info "Timezone → synced"
  else
    info "Timezone → skipped"
  fi
}

# ---------------------------------------------------------------------------
# Input devices
# ---------------------------------------------------------------------------
select_input_devices() {
  local -n _opts=$1

  section "🕹️  Input Devices"
  printf '%s→ -v /dev/input:/dev/input%s\n\n' "$DIM" "$RST" >&2

  printf 'Mount host input devices (keyboard,\n' >&2
  printf 'mouse, joystick) into container.\n\n' >&2

  if confirm "Mount /dev/input?" "y"; then
    _opts+=(-v /dev/input:/dev/input)
    info "Input devices → mounted"
  else
    info "Input devices → skipped"
  fi
}

# ---------------------------------------------------------------------------
# Home directory mount
# ---------------------------------------------------------------------------
select_home_mount() {
  local -n _opts=$1
  local host_home="/home/$USER"

  section "🏠 Home Directory Mount"
  printf '%s→ -v %s:<DST>%s\n\n' "$DIM" "$host_home" "$RST" >&2

  printf 'Mount host home directory into container:\n\n' >&2

  local choice
  choice=$(menu 4 \
    "$host_home → /home/$USER" \
    "$host_home → /home/host" \
    "$host_home → /root/host-home" \
    "Do not mount")
  case "$choice" in
  1)
    _opts+=(-v "$host_home:/home/$USER")
    info "Home → /home/$USER"
    ;;
  2)
    _opts+=(-v "$host_home:/home/host")
    info "Home → /home/host"
    ;;
  3)
    _opts+=(-v "$host_home:/root/host-home")
    info "Home → /root/host-home"
    ;;
  4) info "Home → not mounted" ;;
  esac
}

# ---------------------------------------------------------------------------
# Extra volumes
# ---------------------------------------------------------------------------
select_extra_volumes() {
  local -n _opts=$1

  section "📁 Extra Volumes"
  printf '%s→ -v <SRC>:<DST>%s\n\n' "$DIM" "$RST" >&2

  local count=0 vol
  while true; do
    vol=$(prompt "Volume mount, without -v flag\n   e.g. /data:/data\n        /host/src:/container/dst\n        /logs:/logs:ro\n        /cache:/cache:rw\n   Press Enter to finish")
    [[ -z $vol ]] && break
    if [[ $vol == -* ]]; then
      warn "Do not include flags like -v, just enter the path (e.g. /data:/data)"
      printf '\n' >&2
      continue
    fi
    if [[ $vol != *:* ]]; then
      warn "Invalid format, expected SRC:DST (e.g. /data:/data)"
      printf '\n' >&2
      continue
    fi
    _opts+=(-v "$vol")
    ((++count))
    info "Added → -v $vol"
    printf '\n' >&2
  done
  if ((count > 0)); then
    info "Extra volumes → $count added"
  else
    info "Extra volumes → none"
  fi
}

# ---------------------------------------------------------------------------
# Build command
# ---------------------------------------------------------------------------
build_cmd() {
  local image="$1" name="$2" cmd="$3"
  local -n _extra_opts=$4

  CMD_ARRAY=(docker run -itd "${_extra_opts[@]}")

  if [[ -n $name ]]; then
    CMD_ARRAY+=(--name "$name")
  fi
  CMD_ARRAY+=("$image")
  # shellcheck disable=SC2086
  CMD_ARRAY+=($cmd)
}

# ---------------------------------------------------------------------------
# Review and execute
# ---------------------------------------------------------------------------
print_command() {
  local -a lines=()
  local i=2 # skip "docker" "run"
  while ((i < ${#CMD_ARRAY[@]})); do
    local arg="${CMD_ARRAY[i]}"
    case "$arg" in
    -e | -v | --name | --device | --label)
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

  printf '%sdocker run \\\n' "$CYAN" >&2
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
  info "Creating container..."

  local container_id
  container_id=$("${CMD_ARRAY[@]}") || die "failed to create container"

  printf '\n' >&2
  success "Container created! ID: ${container_id:0:12}"
}

post_create() {
  local name="$1"
  local display_name="$name"
  if [[ -z $display_name ]]; then
    display_name=$(docker ps -l --format '{{.Names}}' 2>/dev/null) ||
      true
  fi
  [[ -z $display_name ]] && return

  printf '\n' >&2
  if confirm "🚪 Enter '$display_name' now?" "y"; then
    local shell_idx
    shell_idx=$(menu 1 "bash" "zsh")
    local -a shell_map=(bash zsh)
    local shell="${shell_map[shell_idx - 1]}"
    exec docker exec -it "$display_name" "$shell"
  else
    printf '\n' >&2
    info "Enter later:  docker exec -it $display_name bash"
    info "Attach later: docker attach $display_name"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    usage
  fi

  local image_arg="${1:-}" name_arg="${2:-}" cmd_arg="${3:-}"

  banner

  local image
  image=$(select_image "$image_arg")
  info "Image → $image"

  local name
  name=$(read_container_name "$name_arg")
  if [[ -n $name ]]; then
    info "Name → $name"
  else
    info "Name → (auto-generated)"
  fi

  local cmd
  cmd=$(read_command "$cmd_arg")
  info "Command → $cmd"

  local -a opts=()
  select_restart opts
  select_privileged opts
  select_ipc opts
  select_network opts
  select_gpu opts

  select_x11 opts

  select_timezone opts
  select_input_devices opts
  select_home_mount opts
  select_extra_volumes opts

  build_cmd "$image" "$name" "$cmd" opts
  confirm_and_run
  post_create "$name"
}

main "$@"
