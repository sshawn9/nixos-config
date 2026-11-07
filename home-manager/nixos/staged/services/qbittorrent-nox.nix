{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.qbittorrent-nox;
  configFile = "${config.xdg.configHome}/qBittorrent/qBittorrent.conf";
  defaultConfig = pkgs.writeText "qBittorrent.conf" ''
    [BitTorrent]
    Session\Port=29102
    Session\AddTrackersFromURLEnabled=true
    Session\AdditionalTrackersURL=https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt
    Session\GlobalMaxRatio=0
    Session\GlobalUPSpeedLimit=100
    Session\DefaultSavePath=${config.xdg.userDirs.download}/qBittorrent
    Session\BTProtocol=Both
    Session\DHTEnabled=true
    Session\PeXEnabled=true
    Session\LSDEnabled=true
    Session\Encryption=0
    Session\MaxConnections=500
    Session\MaxConnectionsPerTorrent=100
    Session\Preallocation=false

    [LegalNotice]
    Accepted=true

    [Preferences]
    General\Locale=zh_CN

    [WebUI]
    Address=*
    Port=29101
    ReverseProxySupportEnabled=true
    TrustedReverseProxiesList=127.0.0.1
    LocalHostAuth=false
  '';
  # qBittorrent rewrites this file at runtime, so only seed it once to keep
  # settings changed in the WebUI, including the password.
  seedConfig = pkgs.writeShellScript "qbittorrent-nox-seed-config" ''
    config_file=${lib.escapeShellArg configFile}
    if [ ! -e "$config_file" ]; then
      ${pkgs.coreutils}/bin/install -Dm600 ${defaultConfig} "$config_file"
    fi
  '';
in
{
  options.my.services.qbittorrent-nox.enable = lib.mkEnableOption "qBittorrent-nox BitTorrent client";

  config = lib.mkIf cfg.enable {
    # Stable path for the user-level Caddyfile, which cannot reference the store path.
    xdg.dataFile."vuetorrent".source = "${pkgs.unstable.vuetorrent}/share/vuetorrent/public";

    systemd.user.services.qbittorrent-nox = {
      Unit.Description = "qBittorrent-nox BitTorrent client";
      Service = {
        ExecStartPre = toString seedConfig;
        ExecStart = "${lib.getExe pkgs.unstable.qbittorrent-nox} --confirm-legal-notice";
        Restart = "on-failure";
        TimeoutStopSec = 1800;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
