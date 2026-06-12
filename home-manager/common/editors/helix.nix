{
  lib,
  pkgs,
  ...
}:
{
  programs = {
    helix = {
      enable = lib.mkDefault false;
      package = pkgs.unstable.helix;
    };
  };
}
