{
  myLib,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (myLib) mkHomePackages;
  aria2ConfigDir = "${config.xdg.configHome}/aria2";
  aria2ConfigFile = "${aria2ConfigDir}/aria2.conf";
  aria2BtPort = 6881;
  aria2CacheDir = "${config.xdg.cacheHome}/aria2";
  aria2StateDir = "${config.xdg.stateHome}/aria2";
  aria2Session = "${aria2StateDir}/aria2.session";
  aria2TrackersFile = "${aria2StateDir}/trackers.txt";
  aria2TrackersUrl = "https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt";
  aria2Settings = {
    dir = "${config.home.homeDirectory}/Downloads";
    input-file = aria2Session;
    save-session = aria2Session;
    save-session-interval = 60;
    force-save = true;
    continue = true;

    enable-rpc = true;
    rpc-listen-all = false;
    rpc-allow-origin-all = true;
    rpc-listen-port = 6800;

    max-concurrent-downloads = 5;
    max-connection-per-server = 8;
    split = 8;
    min-split-size = "10M";
    disk-cache = "64M";
    file-allocation = "falloc";

    bt-save-metadata = true;
    bt-load-saved-metadata = true;
    bt-max-peers = 128;
    dht-file-path = "${aria2CacheDir}/dht.dat";
    dht-file-path6 = "${aria2CacheDir}/dht6.dat";
    dht-listen-port = aria2BtPort;
    enable-dht = true;
    enable-peer-exchange = true;
    listen-port = aria2BtPort;
    seed-ratio = 0.0;
    seed-time = 0;
    max-overall-upload-limit = "100K";
    auto-file-renaming = true;
  };
  aria2BaseConfig = (pkgs.formats.keyValue { }).generate "aria2.conf" aria2Settings;
  aria2UpdateConfig = pkgs.writeShellScript "aria2-update-config" ''
    set -o pipefail

    config_dir=${lib.escapeShellArg aria2ConfigDir}
    config_file=${lib.escapeShellArg aria2ConfigFile}
    config_tmp="$config_file.tmp"
    base_config=${lib.escapeShellArg aria2BaseConfig}
    trackers_dir=${lib.escapeShellArg aria2StateDir}
    trackers_file=${lib.escapeShellArg aria2TrackersFile}
    trackers_url=${lib.escapeShellArg aria2TrackersUrl}
    trackers_tmp="$trackers_file.tmp"

    ${pkgs.coreutils}/bin/mkdir -p "$config_dir"
    ${pkgs.coreutils}/bin/mkdir -p "$trackers_dir"

    if ${pkgs.curl}/bin/curl -fsSL --connect-timeout 8 --retry 2 --retry-delay 1 "$trackers_url" \
      | ${pkgs.gnugrep}/bin/grep -E '^(udp|http|https)://' > "$trackers_tmp"; then
      if [ -s "$trackers_tmp" ]; then
        ${pkgs.coreutils}/bin/mv "$trackers_tmp" "$trackers_file"
        echo "Updated aria2 trackers from $trackers_url"
      else
        ${pkgs.coreutils}/bin/rm -f "$trackers_tmp"
        echo "Fetched aria2 trackers list was empty; keeping existing cache if present." >&2
      fi
    else
      ${pkgs.coreutils}/bin/rm -f "$trackers_tmp"
      echo "Failed to update aria2 trackers; keeping existing cache if present." >&2
    fi

    ${pkgs.coreutils}/bin/rm -f "$config_tmp"
    ${pkgs.coreutils}/bin/install -m 0644 "$base_config" "$config_tmp"

    if [ -s "$trackers_file" ]; then
      trackers="$(
        ${pkgs.gnugrep}/bin/grep -E '^(udp|http|https)://' "$trackers_file" \
          | ${pkgs.coreutils}/bin/tr '\n' ',' \
          | ${pkgs.gnused}/bin/sed 's/,$//'
      )"

      if [ -n "$trackers" ]; then
        printf 'bt-tracker=%s\n' "$trackers" >> "$config_tmp"

        escaped_trackers="$(
          printf '%s' "$trackers" \
            | ${pkgs.gnused}/bin/sed 's/\\/\\\\/g; s/"/\\"/g'
        )"

        if ${pkgs.curl}/bin/curl -fsS --connect-timeout 2 \
          -H 'Content-Type: application/json' \
          --data "{\"jsonrpc\":\"2.0\",\"id\":\"update-trackers\",\"method\":\"aria2.changeGlobalOption\",\"params\":[{\"bt-tracker\":\"$escaped_trackers\"}]}" \
          http://127.0.0.1:6800/jsonrpc >/dev/null 2>&1; then
          echo "Updated running aria2 tracker options."
        fi
      fi
    fi

    ${pkgs.coreutils}/bin/mv "$config_tmp" "$config_file"
  '';
in
{
  imports = [
    (mkHomePackages {
      ariang = {
        # TODO
        # Keep AriaNg on stable until upstream refreshes its npm lockfile.
        # AriaNg 1.3.13 still ships a lockfileVersion=1 package-lock while
        # depending on angular-input-dropdown via a git URL; npm 11's `npm ci`
        # rejects that as package.json/package-lock drift:
        #   Invalid: lock file's angular-input-dropdown@ does not satisfy angular-input-dropdown@1.1.2
        # Track:
        #   https://github.com/mayswind/AriaNg/blob/1.3.13/package.json#L14
        #   https://github.com/mayswind/AriaNg/blob/1.3.13/package-lock.json#L4
        #   https://docs.npmjs.com/cli/v11/commands/npm-ci
        #   https://github.com/NixOS/nixpkgs/issues/523144
        package = pkgs.pkgs2511.ariang;
      };
    })
  ];

  programs = {
    aria2 = {
      package = lib.mkDefault pkgs.unstable.aria2;
      systemd.enable = lib.mkDefault pkgs.stdenv.isLinux;
    };

    aria2p = {
      package = lib.mkDefault pkgs.unstable.python3Packages.aria2p;
    };
  };

  home.activation.updateAria2Config = lib.mkIf config.programs.aria2.enable (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${aria2UpdateConfig}
    ''
  );

  systemd.user.services.aria2 = lib.mkIf config.programs.aria2.enable {
    Unit.X-Restart-Triggers = [ aria2BaseConfig ];

    Service.ExecStartPre = [
      "${pkgs.coreutils}/bin/mkdir -p ${aria2CacheDir}"
      "${pkgs.coreutils}/bin/mkdir -p ${aria2StateDir}"
      "${pkgs.coreutils}/bin/touch ${aria2Session}"
      "${aria2UpdateConfig}"
    ];
  };
}
