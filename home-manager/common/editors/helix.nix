{
  lib,
  pkgs,
  ...
}:
{
  programs = {
    helix = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.helix;
    };
  };
}
