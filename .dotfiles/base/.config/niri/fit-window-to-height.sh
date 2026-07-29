#!/usr/bin/env bash

set -euo pipefail

readonly CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly NIRI_LAYOUT_FILE="$CONFIG_HOME/niri/layout.kdl"
readonly NOCTALIA_SETTINGS_FILE="$CONFIG_HOME/noctalia/settings.json"

die() {
    printf 'fit-window-to-height: %s\n' "$*" >&2
    exit 1
}

require_dependencies() {
    local required_command

    for required_command in niri jq awk; do
        command -v "$required_command" >/dev/null 2>&1 ||
            die "$required_command is not available"
    done
}

# Output fields: window ID, width, height, workspace ID.
get_focused_window() {
    local window_json

    window_json=$(niri msg --json focused-window) ||
        die "cannot read the focused window"

    jq -er '
        [
            .id,
            .layout.window_size[0],
            .layout.window_size[1],
            .workspace_id
        ]
        | @tsv
    ' <<<"$window_json" || die "focused window has incomplete layout data"
}

get_window_output_name() {
    local workspace_id=$1

    niri msg --json workspaces |
        jq -er --argjson workspace_id "$workspace_id" '
            .[]
            | select(.id == $workspace_id)
            | .output
        ' || die "cannot find the window output"
}

# Output fields: logical height, scale.
get_output_metrics() {
    local output_name=$1

    niri msg --json outputs |
        jq -er --arg output "$output_name" '
            .[$output].logical
            | [.height, .scale]
            | @tsv
        ' || die "cannot read metrics for output $output_name"
}

get_niri_gaps() {
    local gaps

    gaps=$(
        awk '$1 == "gaps" { print $2; exit }' "$NIRI_LAYOUT_FILE" 2>/dev/null ||
            true
    )

    printf '%s\n' "${gaps:-0}"
}

# Output fields: position, density, display mode, bar type, vertical margin,
# whether the one-physical-pixel exclusion inset is enabled.
get_noctalia_bar_config() {
    local output_name=$1

    jq -cer --arg output "$output_name" '
        .bar as $bar
        | (($bar.screenOverrides // [])
            | map(select(.name == $output and .enabled != false))
            | first // {}) as $override
        | [
            ($override.position // $bar.position // "top"),
            ($override.density // $bar.density // "default"),
            ($override.displayMode // $bar.displayMode // "always_visible"),
            ($bar.barType // "simple"),
            ($bar.marginVertical // 0),
            ($bar.enableExclusionZoneInset // false)
        ]
        | @tsv
    ' "$NOCTALIA_SETTINGS_FILE" || die "cannot read Noctalia bar settings"
}

get_noctalia_density_height() {
    local density=$1

    case "$density" in
    mini) printf '21\n' ;;
    compact) printf '25\n' ;;
    comfortable) printf '37\n' ;;
    spacious) printf '47\n' ;;
    *) printf '31\n' ;;
    esac
}

calculate_noctalia_bar_reserve() {
    local output_name=$1
    local output_scale=$2
    local bar_config position density display_mode bar_type margin_vertical inset
    local density_height

    if [[ ! -r $NOCTALIA_SETTINGS_FILE ]]; then
        printf '0\n'
        return
    fi

    bar_config=$(get_noctalia_bar_config "$output_name")
    IFS=$'\t' read -r \
        position density display_mode bar_type margin_vertical inset \
        <<<"$bar_config"

    if [[ $display_mode == auto_hide || $display_mode == non_exclusive ]]; then
        printf '0\n'
        return
    fi

    if [[ $position != top && $position != bottom ]]; then
        printf '0\n'
        return
    fi

    density_height=$(get_noctalia_density_height "$density")

    jq -nr \
        --argjson density_height "$density_height" \
        --argjson margin_vertical "$margin_vertical" \
        --argjson output_scale "$output_scale" \
        --arg bar_type "$bar_type" \
        --arg inset "$inset" '
            $density_height
            + (if $bar_type == "floating" then ($margin_vertical | ceil) else 0 end)
            - (if $inset == "true" then 1 / $output_scale else 0 end)
        '
}

# Output fields: target width, target height.
calculate_target_size() {
    local current_width=$1
    local current_height=$2
    local output_height=$3
    local bar_reserve=$4
    local gaps=$5

    jq -nr \
        --argjson current_width "$current_width" \
        --argjson current_height "$current_height" \
        --argjson output_height "$output_height" \
        --argjson bar_reserve "$bar_reserve" \
        --argjson gaps "$gaps" '
            ($output_height - $bar_reserve - 2 * $gaps | round) as $target_height
            | ($target_height * $current_width / $current_height | floor) as $target_width
            | [$target_width, $target_height]
            | @tsv
        '
}

apply_window_size() {
    local window_id=$1
    local target_width=$2
    local target_height=$3

    # Keep addressing the original window even if focus changes while this
    # helper is running.
    niri msg action set-window-width --id "$window_id" "$target_width"
    niri msg action set-window-height --id "$window_id" "$target_height"
}

main() {
    local dry_run=false
    local window_data window_id current_width current_height workspace_id
    local output_name output_metrics output_height output_scale
    local gaps bar_reserve target_size target_width target_height

    case "${1:-}" in
    "") ;;
    --dry-run) dry_run=true ;;
    *) die "usage: ${0##*/} [--dry-run]" ;;
    esac

    require_dependencies

    window_data=$(get_focused_window)
    IFS=$'\t' read -r window_id current_width current_height workspace_id \
        <<<"$window_data"

    ((current_width > 0 && current_height > 0)) ||
        die "focused window has an invalid size"

    output_name=$(get_window_output_name "$workspace_id")
    output_metrics=$(get_output_metrics "$output_name")
    IFS=$'\t' read -r output_height output_scale <<<"$output_metrics"

    gaps=$(get_niri_gaps)
    bar_reserve=$(calculate_noctalia_bar_reserve "$output_name" "$output_scale")
    target_size=$(
        calculate_target_size \
            "$current_width" \
            "$current_height" \
            "$output_height" \
            "$bar_reserve" \
            "$gaps"
    )
    IFS=$'\t' read -r target_width target_height <<<"$target_size"

    ((target_width > 0 && target_height > 0)) ||
        die "calculated an invalid target size"

    if [[ $dry_run == true ]]; then
        printf 'window=%s output=%s current=%sx%s target=%sx%s\n' \
            "$window_id" "$output_name" \
            "$current_width" "$current_height" \
            "$target_width" "$target_height"
        return
    fi

    apply_window_size "$window_id" "$target_width" "$target_height"
}

main "$@"
