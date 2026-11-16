{ config, lib, ... }:
let
  cfg = config.features.qbittorrent;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.qbittorrent.enable {
    networking.firewall = {
      allowedTCPPorts = [ cfg.peerPort ];
      allowedUDPPorts = [ cfg.peerPort ];
    };
  };
}
