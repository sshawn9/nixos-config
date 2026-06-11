{
  lib,
  pkgs,
  ...
}:
{
  services.flatpak = {
    enable = lib.mkDefault true;
    package = pkgs.unstable.flatpak;
  };
}
