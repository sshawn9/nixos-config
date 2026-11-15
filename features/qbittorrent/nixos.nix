{ config, lib, ... }:
let
  cfg = config.features.qbittorrent;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [ cfg.peerPort ];
      allowedUDPPorts = [ cfg.peerPort ];
    };
  };
}
