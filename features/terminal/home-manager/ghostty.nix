{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
in
{
  config = lib.mkIf config.features.terminal.enable {
    xdg.configFile."ghostty" = lib.mkIf config.programs.ghostty.enable (link "ghostty");

    programs.ghostty = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.ghostty;
      installBatSyntax = lib.mkDefault true;
      installVimSyntax = lib.mkDefault true;
      systemd.enable = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (lib.mkDefault true);
    };
  };
}
