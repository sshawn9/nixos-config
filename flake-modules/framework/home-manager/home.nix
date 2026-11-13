{ lib, ... }:
{
  home.stateVersion = lib.mkDefault "25.11";
  xdg.enable = lib.mkDefault true;
}
