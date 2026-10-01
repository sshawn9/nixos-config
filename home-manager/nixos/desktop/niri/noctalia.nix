{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  config = lib.mkIf config.my.shared.desktops.niri.enable {
    programs.noctalia.enable = lib.mkDefault true;

    xdg.configFile."noctalia" = config.my.paths.local.xdgConfigLayeredTree "noctalia";
    xdg.dataFile."noctalia/plugins" = config.my.paths.local.xdgDataLayeredTree "noctalia/plugins";

    home.packages = [
      pkgs.unstable.udiskie
      pkgs.unstable.ddcutil # DDC/CI brightness control for external monitors.
    ];
  };
}
