{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    zellij = {
      enable = lib.mkDefault true;
      package = pkgs.unstable.zellij;
    };
  };
}
