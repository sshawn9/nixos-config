{
  lib,
  config,
  ...
}:
{
  xdg.configFile."haruna" = config.my.paths.local.xdgConfigLayeredTree "haruna";

  my.packages.haruna = lib.mkDefault false;
}
