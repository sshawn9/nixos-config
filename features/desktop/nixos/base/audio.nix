{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.desktop.enable {
    security.rtkit.enable = lib.mkDefault true;
    services.pipewire = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.pipewire;
      wireplumber.enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
    };
  };
}
