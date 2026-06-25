{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    broot = {
      package = lib.mkDefault pkgs.unstable.broot;
    };
  };
}
