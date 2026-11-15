{ lib, pkgs, ... }:
{
  xdg.enable = lib.mkDefault true;
  home.sessionPath = [ "$HOME/.local/bin" ];
  programs.home-manager.enable = lib.mkDefault true;
  nix.package = lib.mkDefault pkgs.unstable.nix;
}
