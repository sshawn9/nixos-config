{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    mosh = {
      enable = lib.mkDefault true;
      package = pkgs.unstable.mosh;
    };
  };
}
