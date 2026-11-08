{
  config,
  lib,
  pkgs,
  ...
}:

let
  fitWindowToHeight = pkgs.writeShellScriptBin "fit-window-to-height" ''
    exec ${pkgs.python3.interpreter} \
      ${lib.escapeShellArg "${config.xdg.configHome}/niri/fit-window-to-height.py"} \
      "$@"
  '';
in
{
  config = lib.mkIf config.my.shared.desktop.niri.enable {
    xdg.configFile."niri" = config.my.paths.local.xdgConfigLayeredTree "niri";

    # Generated so niri follows home.pointerCursor instead of hard-coding the theme and size.
    xdg.configFile."niri/cursor.kdl" = lib.mkIf config.home.pointerCursor.enable {
      text = ''
        cursor {
            xcursor-theme "${config.home.pointerCursor.name}"
            xcursor-size ${toString config.home.pointerCursor.size}
        }
      '';
    };

    home.packages = [ fitWindowToHeight ];
  };
}
