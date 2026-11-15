{ lib, pkgs, ... }:
{
  package = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    wtype = lib.mkDefault true;
  };
}
