{
  lib,
  pkgs,
  ...
}:
{
  programs = {
    vscode = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.vscode;
    };
  };
}
