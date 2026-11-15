{ lib, ... }:
{
  options.features.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent";

    peerPort = lib.mkOption {
      type = lib.types.port;
      default = 29101;
      description = "Peer port opened in the firewall and seeded into qBittorrent.conf.";
    };

    webuiPort = lib.mkOption {
      type = lib.types.port;
      default = 29102;
      description = "Web UI port seeded into qBittorrent.conf.";
    };
  };
}
