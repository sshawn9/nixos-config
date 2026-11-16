{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.features.programs-cli.enable && pkgs.stdenv.hostPlatform.isLinux) {
    package = {
      perf = lib.mkDefault true;
      lm_sensors = lib.mkDefault false;
      psmisc = lib.mkDefault true;
      iotop = lib.mkDefault true;
    };
  };
}
