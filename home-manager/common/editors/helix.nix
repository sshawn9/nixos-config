{
  lib,
  pkgs,
  ...
}:
{
  programs = {
    helix = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.helix;
    };
  };
}
