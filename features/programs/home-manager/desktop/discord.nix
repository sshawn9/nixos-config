{ lib, pkgs, ... }:
{
  programs.discord = {
    enable = lib.mkDefault false;
    package = lib.mkDefault pkgs.unstable.discord;
  };
}
