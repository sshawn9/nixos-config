# Fetch Waydroid images.
# You can add the parameters "-s GAPPS -f" to have GApps support.
# $ sudo waydroid init
# https://wiki.nixos.org/wiki/Waydroid

{ lib, pkgs, ... }:

{
  virtualisation = {
    waydroid = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.waydroid-nftables;
    };
  };
}
