{
  lib,
  pkgs,
  config,
  ...
}:
{
  services.flatpak = {
    enable = lib.mkDefault (config.my.shared.desktop.active != [ ]);
    package = lib.mkDefault pkgs.unstable.flatpak;
  };
}
