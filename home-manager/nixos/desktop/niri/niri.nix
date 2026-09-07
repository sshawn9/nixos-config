{
  config,
  lib,
  pkgs,
  ...
}:

let
  fitWindowToHeight = pkgs.writers.writePython3Bin "fit-window-to-height" { } ''
    import runpy

    runpy.run_path(
        ${builtins.toJSON "${config.xdg.configHome}/niri/fit-window-to-height.py"},
        run_name="__main__",
    )
  '';
in
{
  config = lib.mkIf config.my.shared.desktops.niri.enable {
    dconf.settings."org/gnome/desktop/interface".toolkit-accessibility = true;

    xdg.configFile."niri" = config.my.paths.local.xdgConfigLayeredTree "niri";
    home.packages = [ fitWindowToHeight ];
  };
}
