{
  lib,
  pkgs,
  ...
}:
{
  programs = {
    vscode = {
      enable = lib.mkDefault false;
      package = pkgs.unstable.vscode;
      mutableExtensionsDir = false;
    };
  };
}
