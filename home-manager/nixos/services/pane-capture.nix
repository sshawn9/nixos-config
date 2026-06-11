{
  config,
  lib,
  pkgs,
  ...
}:

# ── Phase B: Periodic Zellij/tmux pane content capture ───────────────
# ActivityWatch captures window metadata (app + title) but cannot see
# the actual terminal output. This module enumerates all Zellij sessions
# and tmux panes every 2 minutes, dumping the visible + scrollback
# content to ~/.local/share/context-capture/.
# Phase D's context-summarizer does not yet read these files (kept
# simple for now), but users can manually `cat | claude code` to feed
# them to an AI assistant for context.
#
# ⚠️ Known limitation: bare Ghostty shells (without Zellij/tmux) are
# not captured. Ghostty itself has a write_scrollback_file action for
# manual dumps, but that is out of scope for this module.
let
  cfg = config.my.services.pane-capture;

  # pkgs.writeShellApplication: compiles an inline shell script into a
  # proper derivation. Benefits:
  #   1. Automatic shellcheck static analysis (typos in variable names
  #      cause a build failure immediately)
  #   2. runtimeInputs are injected into PATH automatically, so `tmux`,
  #      `zellij`, and `sha256sum` do not need absolute paths
  #   3. Automatically prepends `set -o errexit -o nounset -o pipefail`
  captureScript = pkgs.writeShellApplication {
    name = "pane-capture";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
      pkgs.gawk
    ]
    # lib.optional cond x: returns [x] when cond is true, [] otherwise.
    # Difference from lib.optionals: optionals takes a list; optional
    # takes a single element. We use optional here because we add one
    # package at a time.
    ++ lib.optional cfg.captureZellij pkgs.unstable.zellij
    ++ lib.optional cfg.captureTmux pkgs.unstable.tmux;
    # ⚠️ Note: pkgs.unstable.zellij/tmux are pinned here. If the user's
    # running zellij/tmux was installed from a different channel (e.g.,
    # started temporarily inside nix-shell), the script will use the
    # runtimeInputs copy to connect to the session socket. The
    # client/server protocol is compatible across minor versions, so
    # this should be fine — but it is an implicit assumption.
    #
    # ── Script logic overview for the text = '' block below ──────────
    # 1. Prepare the dest directory and current timestamp `now`
    # 2. Define the write_if_changed helper (dedup before writing)
    # 3. lib.optionalString cfg.captureZellij embeds:
    #      - zellij list-sessions to enumerate all sessions
    #      - `zellij action dump-screen` per session → temp file →
    #        write_if_changed → <session>.latest.txt
    #      - tr -c 'A-Za-z0-9._-' '_' sanitises special chars in the
    #        session name to prevent path injection
    # 4. lib.optionalString cfg.captureTmux embeds:
    #      - tmux list-panes -a to enumerate session × window × pane
    #      - tmux capture-pane -p -S - to grab full history + visible
    #      - same write_if_changed path → <pane-id>.latest.txt
    # 5. Any per-step failure is swallowed with `|| true` so one
    #    failing pane does not block the rest
    text = ''
      # writeShellApplication adds this automatically; kept explicitly for readability.
      set -euo pipefail

      dest="${cfg.dataDir}"
      mkdir -p "$dest/zellij" "$dest/tmux"

      now="$(date -u +%Y%m%dT%H%M%SZ)"

      # ── Dedup-write helper ──────────────────────────────────────
      # Usage: echo "<content>" | write_if_changed /path/to/output
      # Steps:
      #   1. Read stdin into a temp file
      #   2. Discard immediately if empty
      #   3. Compute sha256; compare against the <output>.lasthash marker
      #   4. Hash matches → content unchanged; discard tmpfile, skip write
      #   5. Hash differs → mv tmp → output; update marker
      # This is the core dedup logic: runs every 2 minutes, but only
      # writes to disk when content actually changes. Without it, the
      # same pane would produce ~260,000 duplicate files per year.
      write_if_changed() {
        local path="$1"
        local tmp
        tmp="$(mktemp)"
        cat > "$tmp"
        if [[ ! -s "$tmp" ]]; then
          rm -f "$tmp"
          return
        fi
        local hash
        hash="$(sha256sum "$tmp" | awk '{print $1}')"
        local marker="$path.lasthash"
        if [[ -f "$marker" ]] && [[ "$(cat "$marker")" == "$hash" ]]; then
          rm -f "$tmp"
          return
        fi
        mv "$tmp" "$path"
        printf '%s' "$hash" > "$marker"
      }

      ${lib.optionalString cfg.captureZellij ''
        if command -v zellij >/dev/null 2>&1; then
          zellij list-sessions --no-formatting --short 2>/dev/null | while read -r session; do
            [[ -z "$session" ]] && continue
            safe="$(printf '%s' "$session" | tr -c 'A-Za-z0-9._-' '_')"
            out="$dest/zellij/''${safe}-''${now}.txt"
            zellij --session "$session" action dump-screen "$out" 2>/dev/null || true
            if [[ -f "$out" ]]; then
              write_if_changed "$dest/zellij/''${safe}.latest.txt" < "$out"
              rm -f "$out"
            fi
          done
        fi
      ''}

      ${lib.optionalString cfg.captureTmux ''
        if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
          tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null | while read -r target; do
            [[ -z "$target" ]] && continue
            safe="$(printf '%s' "$target" | tr -c 'A-Za-z0-9._-' '_')"
            content="$(tmux capture-pane -p -S - -t "$target" 2>/dev/null || true)"
            [[ -z "$content" ]] && continue
            printf '%s' "$content" | write_if_changed "$dest/tmux/''${safe}.latest.txt"
          done
        fi
      ''}
    '';
  };
in
{
  options.my.services.pane-capture = {
    enable = lib.mkEnableOption "Periodic Zellij/tmux pane content capture";

    # interval: passed to the systemd timer's OnUnitActiveSec field
    # ("trigger N time after the last completion"), not OnCalendar.
    # 2 minutes is a trade-off between coverage and disk usage: shorter
    # risks capturing incomplete transient states; longer risks missing
    # short-lived commands.
    interval = lib.mkOption {
      type = lib.types.str;
      default = "2min";
      description = "systemd OnUnitActiveSec interval between captures.";
    };

    # dataDir: all captured dumps land here. Only one file is kept per
    # session/pane (write_if_changed uses the fixed name .latest.txt).
    # ⚠️ User decision required: do you want logrotate? Currently only
    # the latest snapshot is retained and the previous one is
    # overwritten — this is intentional. For long-term archiving, the
    # write_if_changed naming strategy must be changed to embed the
    # `now` timestamp in the filename.
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local/share/context-capture";
      description = "Destination directory for pane dumps.";
    };

    # Both default to true: the user has used both multiplexers,
    # so enabling both by default avoids extra configuration.
    captureZellij = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Capture all Zellij sessions via `zellij action dump-screen`.";
    };

    captureTmux = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Capture all tmux panes via `tmux capture-pane`.";
    };
  };

  config = lib.mkIf cfg.enable {
    # A service + timer is the standard systemd pair: the service
    # defines *what* to do; the timer defines *when* to do it. Both
    # units share the same name so systemd binds them automatically.
    systemd.user.services.pane-capture = {
      Unit.Description = "Capture Zellij and tmux pane contents for AI context";
      Service = {
        # Type = oneshot: runs once and exits; not a persistent daemon.
        # The timer wakes this service on schedule; each activation is
        # an independent process instance.
        Type = "oneshot";
        ExecStart = "${captureScript}/bin/pane-capture";
      };
    };

    systemd.user.timers.pane-capture = {
      Unit.Description = "Periodic trigger for pane-capture.service";
      Timer = {
        # OnBootSec = 1min: waits 1 minute after boot/login before the
        # first trigger, avoiding the startup peak and racing with
        # zellij/tmux socket initialisation.
        OnBootSec = "1min";
        # OnUnitActiveSec: waits N time after the previous service run
        # completes before triggering the next one. Unlike OnCalendar's
        # fixed schedule, this guarantees a minimum gap of cfg.interval
        # between captures.
        OnUnitActiveSec = cfg.interval;
        # AccuracySec: allows systemd to coalesce wakeups within this
        # window to save power. 10 s is precise enough for captures.
        AccuracySec = "10s";
        # Persistent = true: missed triggers (e.g. during sleep or
        # shutdown) are fired immediately on resume, ensuring no time
        # window is lost due to a period of being offline.
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
