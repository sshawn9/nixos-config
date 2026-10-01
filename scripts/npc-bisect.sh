#!/usr/bin/env bash

set -euo pipefail

# main() is the entrypoint. npc owns the good/bad interval; our checkpoint only
# chooses candidates while an endpoint is missing. Keep these two states separate.

# Run configuration, made read-only after argument parsing and repository setup.
mode=help
input=nixpkgs-unstable
build_args=()
repo_dir=''
search_dir=''
search_file=''

# Durable search state. The JSON keys remain compatible with existing checkpoints.
search_anchor=''
search_original=''
search_phase=''
search_offset=1
search_loaded=false

# Cached history and command results; each is populated by its corresponding reader.
channel_history=()
history_loaded=false
npc_status_kind=absent
npc_session_input=''
npc_revision=''
npc_summary=''
build_exit_code=0
tested_npc_revisions=()

usage() {
    cat <<'EOF'
Usage: npc-bisect.sh [start|resume] [--input NAME] [--] [BUILD_ARGS...]

Automatically run `just build` and report good/bad to npc bisect.
With no command, show this help and exit.

  start       Refresh npc history and test the latest channel revision first.
              If it fails, try the original locked revision as a good candidate,
              then probe 1, 2, 4, 8... releases before the SAME latest revision.
              Requires no existing bisect session; the current pin may be bad.
  resume      Continue the current directory's npc session.
              Find a missing good endpoint automatically, then let npc bisect.
  --input     Direct root flake input (default: nixpkgs-unstable).
  BUILD_ARGS  Arguments passed unchanged to `just build`, e.g. a hostname.

Examples:
  just npc-bisect start
  just npc-bisect resume
  just npc-bisect start -- x --keep-going
  just npc-bisect start --input nixpkgs-2605

Runs in this repository and builds without activation. Use `npc status` to inspect
NPC's state and `npc bisect reset` to finish or start anew. Ctrl+C leaves the build
unmarked; resume with the same build arguments, other inputs and configuration.

A failed original-pin trial is left unmarked. Probes always count back from this
search's latest revision. Once good/bad endpoints are known, npc chooses the next
candidate and eventually selects the last good. No good found is reported as an
error. A passing latest revision ends the search without needing a bad endpoint.

The fixed origin and probe position are saved under $XDG_STATE_HOME/npc-bisect
(default: ~/.local/state/npc-bisect); start replaces this repository's checkpoint.
Ordinary build failures, including network/disk failures, are marked bad. Bisection
assumes one persistent regression; later fixes followed by regressions can be missed.
EOF
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

interrupted() {
    printf '\nStopped; npc state and the current flake.lock are retained.\n' >&2
    exit "$1"
}

parse_arguments() {
    case "${1:-}" in
    start | resume)
        mode=$1
        shift
        ;;
    esac

    while (($#)); do
        case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        --input)
            (($# >= 2)) || die "--input requires a name"
            input=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*) die "unknown option: $1 (put build arguments after --)" ;;
        *) break ;;
        esac
    done
    build_args=("$@")
}

prepare_repository() {
    local dependency
    for dependency in npc jq just awk; do
        command -v "$dependency" >/dev/null || die "missing command: $dependency"
    done

    repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
    cd -- "$repo_dir"
    [[ -f flake.lock ]] || die "flake.lock not found in $repo_dir"
    read_locked_revision >/dev/null

    search_dir=${XDG_STATE_HOME:-"$HOME/.local/state"}/npc-bisect
    search_file="$search_dir/$(jq -rn --arg path "$repo_dir" '$path | @uri').json"
    readonly mode input repo_dir search_dir search_file
    readonly -a build_args
    trap 'interrupted 130' INT
    trap 'interrupted 143' TERM
}

is_revision() {
    [[ $1 =~ ^[0-9a-f]{40}$ ]]
}

read_locked_revision() {
    local revision
    revision=$(jq -er --arg input "$input" '
        .nodes as $nodes
        | $nodes[.root].inputs[$input]
        | select(type == "string")
        | $nodes[.].locked.rev
    ' flake.lock) || die "cannot read $input; use a direct root input, not a follows alias"
    is_revision "$revision" || die "invalid locked revision for $input"
    printf '%s\n' "$revision"
}

checkout_revision() {
    local revision=$1
    is_revision "$revision" || die "invalid candidate revision: $revision"
    if [[ $(read_locked_revision) != "$revision" ]]; then
        npc checkout --input "$input" "$revision"
    fi
}

# npc 1.0 has no machine-readable status command. Interpret its text only here;
# the search logic below uses the normalized kind, input and selected revision.
read_npc_session() {
    local status_text header
    status_text=$(npc status)
    header=${status_text%%$'\n'*}
    npc_summary=${status_text%%$'\n\n'*}
    npc_status_kind=absent
    npc_session_input=''
    npc_revision=''

    case "$header" in
    'done bisecting '*)
        npc_status_kind=complete
        npc_revision=$(awk '$2 == "is" && $3 == "the" && $4 == "last" && $5 == "good" { print $1 }' <<<"$status_text")
        ;;
    'bisecting '*)
        if [[ $status_text == *'waiting for '* ]]; then
            npc_status_kind=waiting
        else
            npc_status_kind=next
            npc_revision=$(awk '$2 == "is" && $3 == "the" && $4 == "next" && $5 == "commit;" { print $1 }' <<<"$status_text")
        fi
        ;;
    *) return 0 ;;
    esac

    if [[ $header == *' for flake input '* ]]; then
        npc_session_input=${header#*' for flake input '}
    fi
    if [[ $npc_status_kind != waiting ]]; then
        is_revision "$npc_revision" || die "unrecognized npc bisect status: $npc_summary"
    fi
}

require_npc_session() {
    [[ $npc_status_kind != absent ]] || die "no bisect session; use start, or initialize one with npc bisect start"
    [[ $npc_session_input == "$input" ]] ||
        die "the existing session is not for flake input $input: $npc_summary"
}

# Sets build_exit_code; it never marks a revision. Call this as a plain command,
# not an `if` predicate, so errexit still catches checkout and evaluation errors.
build_revision() {
    local revision=$1
    checkout_revision "$revision"
    printf '\nBuilding %s\n' "$revision"
    build_exit_code=0
    just build "${build_args[@]}" </dev/null || build_exit_code=$?
    case "$build_exit_code" in
    126 | 127 | 130 | 143)
        printf 'Build aborted (exit %s); no good/bad mark was added.\n' "$build_exit_code" >&2
        exit "$build_exit_code"
        ;;
    esac
    [[ $(read_locked_revision) == "$revision" ]] || die "$input changed during the build; not marking it"
}

# Commit a phase transition, optionally changing the probe offset. Atomic rename
# keeps the previous checkpoint readable if writing the new one is interrupted.
checkpoint_search() {
    local temporary
    search_phase=$1
    search_offset=${2:-$search_offset}
    mkdir -p -- "$search_dir"
    temporary=$(mktemp "$search_file.XXXXXX")
    jq -n --arg input "$input" --arg anchor "$search_anchor" --arg original "$search_original" \
        --arg phase "$search_phase" --argjson offset "$search_offset" \
        '{input: $input, anchor: $anchor, original: $original, phase: $phase, offset: $offset}' >"$temporary"
    mv -f -- "$temporary" "$search_file"
}

initialize_search() {
    local latest
    latest=$(npc log --input "$input" -n 1)
    search_anchor=${latest%% *}
    is_revision "$search_anchor" || die "could not read the latest channel revision"
    search_original=$(read_locked_revision)
    checkpoint_search latest 1
    search_loaded=true
    history_loaded=false
}

load_search() {
    local fields
    fields=$(jq -er --arg input "$input" '
        select(.input == $input)
        | [.anchor, .original, .phase, (.offset | tostring)] | @tsv
    ' "$search_file") || die "invalid search progress for $input; reset npc and use start"
    IFS=$'\t' read -r search_anchor search_original search_phase search_offset <<<"$fields"
    is_revision "$search_anchor" && is_revision "$search_original" && [[ $search_offset =~ ^[1-9][0-9]*$ ]] ||
        die "invalid search progress; reset npc and use start"
    case "$search_phase" in
    latest | original | seek | native | complete | exhausted) ;;
    *) die "unknown search phase: $search_phase" ;;
    esac
    search_loaded=true
}

ensure_search_loaded() {
    [[ $search_loaded == false ]] || return 0
    if [[ -f $search_file ]]; then
        load_search
    else
        initialize_search
    fi
}

# channel_history[0] stays at the saved anchor, even when npc has newer tips.
load_channel_history() {
    [[ $history_loaded == false ]] || return 0
    local history_text candidate rest found_anchor=false
    history_text=$(GIT_PAGER=cat PAGER=cat npc log --input "$input")
    channel_history=()
    while read -r candidate rest; do
        [[ -n $candidate ]] || continue
        is_revision "$candidate" || die "invalid revision in npc history"
        if [[ $candidate == "$search_anchor" ]]; then
            found_anchor=true
        fi
        if [[ $found_anchor == true ]]; then
            channel_history+=("$candidate")
        fi
    done <<<"$history_text"
    [[ $found_anchor == true ]] || die "saved search origin $search_anchor is missing from npc history"
    history_loaded=true
}

finish_with_latest() {
    checkout_revision "$search_anchor"
    printf '\nSearch complete; its latest revision is good: %s\n' "$search_anchor"
    exit 0
}

finish_bisection() {
    # npc may have saved the result just before a failed or interrupted lock update.
    checkout_revision "$npc_revision"
    printf '\nBisection complete; keeping the last good revision.\n%s\n' "$npc_summary"
    exit 0
}

# While an endpoint is missing, each step builds, marks when appropriate, then
# checkpoints the next phase. In particular, the original-pin trial has its own
# failure rule and must not share the probe's automatic bad marking.
test_latest_revision() {
    build_revision "$search_anchor"
    if ((build_exit_code == 0)); then
        npc bisect good "$search_anchor"
        checkpoint_search complete
        finish_with_latest
    fi
    npc bisect bad "$search_anchor"
    checkpoint_search original
}

test_original_revision() {
    local index original_is_older=false
    load_channel_history
    for ((index = 1; index < ${#channel_history[@]}; index++)); do
        if [[ ${channel_history[index]} == "$search_original" ]]; then
            original_is_older=true
            break
        fi
    done
    if [[ $original_is_older == false ]]; then
        checkpoint_search seek
        return 0
    fi

    build_revision "$search_original"
    if ((build_exit_code == 0)); then
        npc bisect good "$search_original"
        checkpoint_search native
    else
        printf 'Original pin failed; leaving it unmarked and probing from %s.\n' "$search_anchor"
        checkpoint_search seek
    fi
}

probe_for_good() {
    local oldest_offset next_offset revision
    load_channel_history
    oldest_offset=$((${#channel_history[@]} - 1))
    if ((oldest_offset == 0)); then
        checkpoint_search exhausted
        die "no earlier channel revisions exist; no good endpoint found"
    fi
    if ((search_offset > oldest_offset)); then
        checkpoint_search seek "$oldest_offset"
    fi

    revision=${channel_history[search_offset]}
    printf '\nProbing %s release(s) before fixed origin %s\n' "$search_offset" "$search_anchor"
    build_revision "$revision"
    if ((build_exit_code == 0)); then
        npc bisect good "$revision"
        checkpoint_search native
        return 0
    fi

    npc bisect bad "$revision"
    if ((search_offset == oldest_offset)); then
        checkpoint_search exhausted
    else
        next_offset=$((search_offset * 2))
        if ((next_offset > oldest_offset)); then next_offset=$oldest_offset; fi
        checkpoint_search seek "$next_offset"
    fi
}

test_npc_candidate() {
    local revision=$1 tested
    for tested in "${tested_npc_revisions[@]}"; do
        [[ $tested != "$revision" ]] || die "npc selected an already tested revision; inspect npc status"
    done
    tested_npc_revisions+=("$revision")

    build_revision "$revision"
    if ((build_exit_code == 0)); then
        npc bisect good "$revision"
    else
        npc bisect bad "$revision"
    fi
}

run_search_step() {
    case "$search_phase" in
    latest) test_latest_revision ;;
    original) test_original_revision ;;
    seek) probe_for_good ;;
    complete) finish_with_latest ;;
    exhausted) die "reached the oldest channel revision without finding good; npc state retained" ;;
    native) die "npc endpoints changed; reset npc and use start for a new search" ;;
    esac
}

start_new_search() {
    npc fetch
    read_npc_session
    [[ $npc_status_kind == absent ]] ||
        die "a bisect session already exists; use resume, or run npc bisect reset before start"

    # Capture the original pin and fixed anchor before anything changes flake.lock.
    initialize_search
    npc bisect start --input "$input"
}

run_search() {
    while true; do
        read_npc_session
        require_npc_session
        # npc's state wins if marking succeeded just before our checkpoint write
        # or its own lock update was interrupted. Never replay an older probe then.
        case "$npc_status_kind" in
        complete) finish_bisection ;;
        next) test_npc_candidate "$npc_revision" ;;
        waiting)
            ensure_search_loaded
            run_search_step
            ;;
        esac
    done
}

main() {
    parse_arguments "$@"
    if [[ $mode == help ]]; then
        usage
        return 0
    fi
    prepare_repository
    if [[ $mode == start ]]; then
        start_new_search
    fi
    run_search
}

main "$@"
