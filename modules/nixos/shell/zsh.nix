{ pkgs, ... }:

{
  users.defaultUserShell = pkgs.unstable.zsh;
}
