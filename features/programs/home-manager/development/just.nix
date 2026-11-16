{ config, lib, ... }:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  config = lib.mkIf config.features.programs.enable {
    xdg.configFile."just" = lib.mkIf config.package.just.enable (link "just");

    package.just = lib.mkDefault true;
  };
}
