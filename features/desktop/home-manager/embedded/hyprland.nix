{
  config,
  lib,
  ...
}:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  config = lib.mkIf (config.features.desktop.enable && config.features.desktop.hyprland.enable) {
    xdg.configFile = {
      "hypr" = link "hypr";
      "uwsm/env-hyprland" = link "uwsm/env-hyprland";
    };
  };
}
