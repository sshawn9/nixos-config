{ config, lib, ... }:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  config = lib.mkIf config.features.programs.enable {
    xdg.configFile."haruna" = lib.mkIf config.package.haruna.enable (link "haruna");

    package.haruna = lib.mkDefault false;
  };
}
