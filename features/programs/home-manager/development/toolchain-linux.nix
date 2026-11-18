{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.features.programs.enable && pkgs.stdenv.hostPlatform.isLinux) {
    package = {
      patchelf = lib.mkDefault true;
      elfutils = lib.mkDefault true;
    };
  };
}
