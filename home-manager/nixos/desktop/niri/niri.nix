{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktops.niri.enable {
    dconf.settings."org/gnome/desktop/interface".toolkit-accessibility = true;

    xdg.configFile."niri" = config.my.paths.local.xdgConfigLayeredTree "niri";
  };
}
