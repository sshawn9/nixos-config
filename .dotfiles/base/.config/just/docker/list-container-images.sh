#!/usr/bin/env bash
# List container images across Docker and Podman rootful/rootless stores.

set -euo pipefail

readonly -a LIST_ARGS=(images --all)
readonly TABLE_FMT='table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}'
readonly COUNT_PREFIX='🖼️  '
readonly COUNT_LABEL='image(s)'
readonly EMPTY_MESSAGE='📭 no images'

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.dotfiles/base/.config/just/docker/list-common.sh
source "$script_dir/list-common.sh"

list_stores "$@"
