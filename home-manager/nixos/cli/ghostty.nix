{
  lib,
  pkgs,
  config,
  ...
}:

{
  xdg.configFile."ghostty" = lib.mkIf config.programs.ghostty.enable (
    config.my.paths.local.xdgConfigLayeredTree "ghostty"
  );

  programs = {
    ghostty = {
      package = lib.mkDefault pkgs.unstable.ghostty;

      installBatSyntax = lib.mkDefault true;
      installVimSyntax = lib.mkDefault true;

      systemd.enable = lib.mkDefault true;
    };
  };
}
