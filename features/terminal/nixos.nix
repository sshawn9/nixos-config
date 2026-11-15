{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zsh.enable = lib.mkDefault true;
  users.defaultUserShell = lib.mkIf config.programs.zsh.enable pkgs.unstable.zsh;
  environment.pathsToLink = lib.mkIf config.programs.zsh.enable [ "/share/zsh" ];
}
