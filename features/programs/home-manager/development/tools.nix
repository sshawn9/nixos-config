{ config, lib, ... }:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  config = lib.mkIf config.features.programs.enable {
    xdg.configFile."just" = lib.mkIf config.package.just.enable (link "just");

    package = {
      watchexec = lib.mkDefault true;
      entr = lib.mkDefault true;
      just = lib.mkDefault true;
      hyperfine = lib.mkDefault true;
      tokei = lib.mkDefault true;
      sqlite = lib.mkDefault true;
      sqlitebrowser = lib.mkDefault false;
      github-desktop = lib.mkDefault false;
    };
  };
}
