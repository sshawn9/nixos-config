{
  lib,
  pkgs,
  ...
}:
{
  services.flatpak = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.unstable.flatpak;
  };
}
