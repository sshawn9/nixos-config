{ config, lib, ... }:

let
  enabled = lib.any (user: user.my.services.qbittorrent-nox.enable or false) (
    builtins.attrValues config.home-manager.users
  );
in
{
  # Match the peer port seeded by home-manager/nixos/services/qbittorrent-nox.nix.
  networking.firewall = lib.mkIf enabled {
    allowedTCPPorts = [ 29102 ];
    allowedUDPPorts = [ 29102 ];
  };
}
