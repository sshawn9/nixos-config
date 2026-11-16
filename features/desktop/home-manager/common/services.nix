{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.desktop.enable {
    services.udiskie = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.udiskie;
    };
    # Noctalia's disk plugin uses these commands through PATH.
    home.packages = lib.mkIf config.services.udiskie.enable [ config.services.udiskie.package ];
  };
}
