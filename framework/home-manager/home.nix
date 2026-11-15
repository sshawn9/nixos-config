{ lib, ... }:
{
  home.stateVersion = lib.mkDefault "25.11";
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
  ];
  xdg.enable = lib.mkDefault true;
}
