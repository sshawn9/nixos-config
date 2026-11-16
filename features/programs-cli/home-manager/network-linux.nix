{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.features.programs-cli.enable && pkgs.stdenv.hostPlatform.isLinux) {
    package = {
      traceroute = lib.mkDefault true;
      ethtool = lib.mkDefault true;
    };
  };
}
