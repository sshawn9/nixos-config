{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.features.desktop.enable {
    package = {
      libsecret = lib.mkDefault true;
      wl-clipboard = lib.mkDefault true;
      wtype = lib.mkDefault true;
      xdg-utils = lib.mkDefault true;
      xdg-user-dirs = lib.mkDefault true;
      playerctl = lib.mkDefault true;
      brightnessctl = lib.mkDefault true;
      ddcutil = lib.mkDefault true;
      nautilus = lib.mkDefault true;
    };
    programs = {
      dconf.enable = lib.mkDefault true;
      xwayland.enable = lib.mkDefault true;
    };
  };
}
