{ config, lib, ... }:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  xdg.configFile."haruna" = lib.mkIf config.package.haruna.enable (link "haruna");

  package.haruna = lib.mkDefault false;
}
