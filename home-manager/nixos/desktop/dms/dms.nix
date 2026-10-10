{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktop.dms.enable {
    xdg.configFile."DankMaterialShell" = config.my.paths.local.xdgConfigLayeredTree "DankMaterialShell";
  };
}
