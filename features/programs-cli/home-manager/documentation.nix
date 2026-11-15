{ lib, pkgs, ... }:
{
  programs = {
    tealdeer = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.tealdeer;
      settings.updates.auto_update = true;
    };
    navi = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.navi;
    };
  };
}
