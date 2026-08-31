{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    devenv = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.devenv;
    };
  };
}
