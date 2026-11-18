{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.programs.enable {
    package = {
      google-chrome = lib.mkDefault false;
      microsoft-edge = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (lib.mkDefault false);
    };
  };
}
