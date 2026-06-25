{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    mosh = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.mosh;
    };
  };
}
