{ lib, pkgs, ... }:
{
  package = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    microsoft-edge = lib.mkDefault false;
    cosmic-files = lib.mkDefault false;
    nemo = lib.mkDefault false;
  };
}
