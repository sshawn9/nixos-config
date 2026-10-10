{
  config,
  lib,
  ...
}:

{
  xdg.enable = lib.mkDefault true;

  xdg.dataFile."personal" = config.my.paths.local.xdgDataLayeredTree "personal";
}
