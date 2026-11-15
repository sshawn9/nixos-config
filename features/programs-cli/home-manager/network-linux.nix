{ lib, pkgs, ... }:
{
  package = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    traceroute = lib.mkDefault true;
    ethtool = lib.mkDefault true;
  };
}
