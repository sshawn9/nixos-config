{
  lib,
  pkgs,
  config,
  ...
}:
{
  services.flatpak = {
    enable = lib.mkDefault (config.my.shared.desktops.active != [ ]);
    package = lib.mkDefault pkgs.unstable.flatpak;
  };
}
