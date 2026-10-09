{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktop.noctalia.enable {
    xdg.configFile."noctalia" = config.my.paths.local.xdgConfigLayeredTree "noctalia";
    xdg.dataFile."noctalia/plugins" = config.my.paths.local.xdgDataLayeredTree "noctalia/plugins";
  };
}
