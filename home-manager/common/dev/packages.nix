{ lib, pkgs, ... }:
{
  my.packages.cc = {
    enable = lib.mkDefault true;
    package = lib.mkDefault (pkgs.unstable or pkgs).stdenv.cc;
  };
}
