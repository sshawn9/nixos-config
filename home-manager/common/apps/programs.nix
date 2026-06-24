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

    opencode = {
      package = lib.mkDefault pkgs.unstable.opencode;
    };
  };
}
