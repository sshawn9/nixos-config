{
  lib,
  pkgs,
  ...
}:
{
  programs.nix-ld = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.unstable.nix-ld;

    # libraries = with pkgs; [];
  };
}
