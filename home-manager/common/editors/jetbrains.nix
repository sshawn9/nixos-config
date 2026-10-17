{ lib, pkgs, ... }:

{
  my.packages = {
    clion = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.jetbrains.clion;
    };
    pycharm = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.jetbrains.pycharm;
    };
    rust-rover = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.jetbrains.rust-rover;
    };
  };
}
