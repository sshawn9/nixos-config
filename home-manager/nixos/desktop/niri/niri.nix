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
    home.packages = [ fitWindowToHeight ];
  };
}
