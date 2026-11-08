{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (config.my.shared.desktop.active != [ ]) {
    services.udiskie = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.udiskie;
    };

    # Noctalia's disk plugin invokes udiskie-info and udiskie-mount through PATH.
    home.packages = lib.mkIf config.services.udiskie.enable [ config.services.udiskie.package ];
  };
}
