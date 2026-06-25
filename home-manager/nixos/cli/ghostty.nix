{
  lib,
  pkgs,
  config,
  ...
}:

{
  xdg.configFile."ghostty" = lib.mkIf config.programs.ghostty.enable {
    source = config.my.paths.local.xdgConfigLayeredSource "ghostty";
  };

  programs = {
    ghostty = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.ghostty;

      installBatSyntax = lib.mkDefault true;
      installVimSyntax = lib.mkDefault true;

      systemd.enable = lib.mkDefault true;
    };
  };
}
