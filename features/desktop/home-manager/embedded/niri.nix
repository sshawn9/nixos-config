{
  config,
  lib,
  ...
}:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  config = lib.mkIf (config.features.desktop.enable && config.features.desktop.niri.enable) {
    xdg.configFile = {
      "niri" = link "niri";
      "niri/cursor.kdl" = lib.mkIf config.home.pointerCursor.enable {
        text = ''
          cursor {
              xcursor-theme "${config.home.pointerCursor.name}"
              xcursor-size ${toString config.home.pointerCursor.size}
          }
        '';
      };
    };
  };
}
