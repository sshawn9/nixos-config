{ lib, pkgs, ... }:
{
  package = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    perf = lib.mkDefault true;
    lm_sensors = lib.mkDefault false;
    psmisc = lib.mkDefault true;
    iotop = lib.mkDefault true;
  };
}
