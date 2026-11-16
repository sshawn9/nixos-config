{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.features.desktop.enable && config.features.desktop.noctalia.enable) {
    programs.noctalia = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.noctalia;
      systemd.enable = lib.mkDefault true;
      recommendedServices.enable = lib.mkDefault true;
    };
  };
}
