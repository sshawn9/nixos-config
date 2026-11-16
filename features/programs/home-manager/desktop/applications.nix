{ config, lib, ... }:
{
  config = lib.mkIf config.features.programs.enable {
    package = {
      obsidian = lib.mkDefault false;
      google-chrome = lib.mkDefault false;
      telegram-desktop = lib.mkDefault false;
      remmina = lib.mkDefault false;
      github-desktop = lib.mkDefault false;
      sqlitebrowser = lib.mkDefault false;
    };
  };
}
