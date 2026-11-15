{ lib, pkgs, ... }:
{
  package = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    patchelf = lib.mkDefault true;
    elfutils = lib.mkDefault true;
    apx = lib.mkDefault false;
  };
}
