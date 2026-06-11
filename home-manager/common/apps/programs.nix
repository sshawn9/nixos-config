{
  lib,
  pkgs,
  ...
}:

{
  programs = {
    codex = {
      package = lib.mkDefault pkgs.unstable.codex;
    };
  };
}
