{ config, lib, ... }:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  xdg.configFile."just" = lib.mkIf config.package.just.enable (link "just");

  package.just = lib.mkDefault true;
}
