{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    zellij = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.zellij;
    };
  };
}
