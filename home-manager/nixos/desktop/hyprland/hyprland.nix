{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktop.hyprland.enable {
    xdg.configFile."hypr" = config.my.paths.local.xdgConfigLayeredTree "hypr";
    xdg.configFile."uwsm/env-hyprland".source =
      config.my.paths.local.xdgConfigLayeredSource "uwsm/env-hyprland";
  };
}
