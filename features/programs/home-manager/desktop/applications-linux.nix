{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.features.programs.enable && pkgs.stdenv.hostPlatform.isLinux) {
    package = {
      microsoft-edge = lib.mkDefault false;
      cosmic-files = lib.mkDefault false;
      nemo = lib.mkDefault false;
    };
  };
}
