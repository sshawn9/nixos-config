{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.features.desktop.enable && config.features.desktop.noctalia.enable) {
    xdg.configFile."noctalia" = config.lib.fileSources.local.xdgConfig.link "noctalia";
    xdg.dataFile."noctalia/plugins" = config.lib.fileSources.local.xdgData.link "noctalia/plugins";
  };
}
