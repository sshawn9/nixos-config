{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktops.niri.enable {
    programs.noctalia = {
      enable = lib.mkDefault true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };

    xdg.configFile."noctalia" = config.my.paths.local.xdgConfigLayeredTree "noctalia";
    xdg.dataFile."noctalia/plugins" = config.my.paths.local.xdgDataLayeredTree "noctalia/plugins";

    home.packages = [
      pkgs.unstable.udiskie
      pkgs.unstable.ddcutil # DDC/CI brightness control for external monitors.
    ];
  };
}
