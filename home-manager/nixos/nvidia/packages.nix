{ lib, pkgs, ... }:
{
  my.packages.nvtop = {
    enable = lib.mkDefault false;
    package = lib.mkDefault pkgs.unstable.nvtopPackages.full;
  };
}
