{ lib, pkgs, ... }:

{
  programs = {
    discord = {
      package = lib.mkDefault pkgs.unstable.discord;
    };
  };
}
