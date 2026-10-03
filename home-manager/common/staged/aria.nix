{
  myLib,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (myLib) mkHomePackages;
  aria2ConfigFile = "${config.xdg.configHome}/aria2/aria2.conf";
  aria2CacheDir = "${config.xdg.cacheHome}/aria2";
  aria2StateDir = "${config.xdg.stateHome}/aria2";
  aria2Session = "${aria2StateDir}/aria2.session";
  aria2TrackersFile = "${aria2StateDir}/trackers.txt";
  aria2TrackersUrl = "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt";
  aria2Start = pkgs.writeShellScript "aria2-start" ''
    set -euo pipefail

    trackers_file=${lib.escapeShellArg aria2TrackersFile}
    args=(--conf-path=${lib.escapeShellArg aria2ConfigFile})
    if [ -s "$trackers_file" ]; then
      args+=("--bt-tracker=$(${pkgs.coreutils}/bin/paste -sd, "$trackers_file")")
    fi

    exec ${lib.getExe config.programs.aria2.package} "''${args[@]}"
  '';
  aria2UpdateTrackers = pkgs.writeShellScript "aria2-update-trackers" ''
    set -euo pipefail

    trackers_dir=${lib.escapeShellArg aria2StateDir}
    trackers_file=${lib.escapeShellArg aria2TrackersFile}
    trackers_url=${lib.escapeShellArg aria2TrackersUrl}

    ${pkgs.coreutils}/bin/mkdir -p "$trackers_dir"
    trackers_tmp="$(${pkgs.coreutils}/bin/mktemp "$trackers_file.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f "$trackers_tmp"' EXIT

    if ! ${pkgs.curl}/bin/curl -fsSL --connect-timeout 8 --max-time 20 --retry 2 --retry-delay 1 "$trackers_url" \
      | ${pkgs.gnugrep}/bin/grep -E '^(udp|http|https)://' > "$trackers_tmp"; then
      echo "Could not fetch a non-empty tracker list; keeping the existing cache." >&2
      exit 1
    fi

    ${pkgs.coreutils}/bin/mv "$trackers_tmp" "$trackers_file"
    echo "Updated aria2 tracker cache."

    if ! ${pkgs.systemd}/bin/systemctl --user --quiet is-active aria2.service; then
      exit 0
    fi

    trackers="$(${pkgs.coreutils}/bin/paste -sd, "$trackers_file")"
    rpc_port="$(
      ${pkgs.gawk}/bin/awk -F= '
        /^[[:space:]]*rpc-listen-port[[:space:]]*=/ { port = $2 }
        END { gsub(/[[:space:]]/, "", port); print port == "" ? 6800 : port }
      ' ${lib.escapeShellArg aria2ConfigFile}
    )"
    if ${pkgs.jq}/bin/jq -cn --arg trackers "$trackers" \
      '{jsonrpc: "2.0", id: "update-trackers", method: "aria2.changeGlobalOption", params: [{"bt-tracker": $trackers}]}' \
      | ${pkgs.curl}/bin/curl -fsS --connect-timeout 2 --max-time 5 \
        -H 'Content-Type: application/json' --data-binary @- \
        "http://127.0.0.1:$rpc_port/jsonrpc" \
      | ${pkgs.jq}/bin/jq -e '.result == "OK" and .error == null' >/dev/null; then
      echo "Updated running aria2 tracker options."
    else
      echo "Tracker cache updated, but RPC update failed; cached trackers will load on the next aria2 start." >&2
      exit 1
    fi
  '';
in
{
  imports = [
    (mkHomePackages {
      ariang = { };
    })
  ];

  xdg.configFile."aria2/aria2.conf" = lib.mkIf config.programs.aria2.enable {
    source = config.my.paths.local.xdgConfigLayeredSource "aria2/aria2.conf";
  };

  programs = {
    aria2 = {
      package = lib.mkDefault pkgs.unstable.aria2;
      systemd.enable = lib.mkDefault pkgs.stdenv.hostPlatform.isLinux;
    };

    aria2p = {
      package = lib.mkDefault pkgs.unstable.python3Packages.aria2p;
    };
  };

  systemd.user.services = lib.mkIf config.programs.aria2.enable {
    aria2.Unit.Wants = [ "aria2-update-trackers.timer" ];
    aria2.Service = {
      ExecStart = lib.mkForce (toString aria2Start);
      ExecStartPre = [
        "${lib.getExe' pkgs.networkmanager "nm-online"} --quiet --timeout=60"
        "${pkgs.coreutils}/bin/mkdir -p ${aria2CacheDir}"
        "${pkgs.coreutils}/bin/mkdir -p ${aria2StateDir}"
        "${pkgs.coreutils}/bin/touch ${aria2Session}"
      ];
      RestartSec = "5s";
    };

    aria2-update-trackers = {
      Unit = {
        Description = "Update aria2 tracker cache and running options";
        After = [ "aria2.service" ];
        BindsTo = [ "aria2.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStartPre = "${lib.getExe' pkgs.networkmanager "nm-online"} --quiet --timeout=60";
        ExecStart = toString aria2UpdateTrackers;
        Restart = "on-failure";
        RestartSec = "5min";
      };
    };
  };

  systemd.user.timers.aria2-update-trackers = lib.mkIf config.programs.aria2.enable {
    Unit = {
      Description = "Update aria2 trackers after startup and daily";
      # Allow ordering after aria2, which starts after basic.target/timers.target.
      DefaultDependencies = false;
      After = [ "aria2.service" ];
      BindsTo = [ "aria2.service" ];
    };
    Timer = {
      OnActiveSec = "5min";
      OnUnitInactiveSec = "1d";
    };
  };
}
