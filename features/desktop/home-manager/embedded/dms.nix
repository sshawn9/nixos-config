{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.features.desktop.enable && config.features.desktop.dms.enable) {
    xdg.configFile."dms" = config.lib.fileSources.local.xdgConfig.link "dms";
  };
}
