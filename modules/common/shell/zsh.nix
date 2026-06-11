{ lib, ... }:

{
  programs.zsh = {
    enable = lib.mkDefault true;
  };
  environment.pathsToLink = [ "/share/zsh" ];
}
