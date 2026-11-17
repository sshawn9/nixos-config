#!/usr/bin/env bash
# List containers across Docker and Podman rootful/rootless stores.

set -euo pipefail

readonly -a LIST_ARGS=(ps -a)
readonly TABLE_FMT='table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.ID}}'
readonly COUNT_PREFIX='📦 '
readonly COUNT_LABEL='container(s)'
readonly EMPTY_MESSAGE='📭 no containers'

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=.dotfiles/base/.config/just/docker/list-common.sh
source "$script_dir/list-common.sh"

list_stores "$@"
