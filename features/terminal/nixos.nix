{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.terminal.enable {
    programs.zsh = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.zsh;
    };
    users.defaultUserShell = lib.mkIf config.programs.zsh.enable pkgs.unstable.zsh;
    environment.pathsToLink = lib.mkIf config.programs.zsh.enable [ "/share/zsh" ];
  };
}
