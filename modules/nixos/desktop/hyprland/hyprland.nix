{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktop.hyprland.enable {
    programs.hyprland = {
      enable = lib.mkDefault true;
      withUWSM = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.hyprland;
      portalPackage = lib.mkDefault pkgs.unstable.xdg-desktop-portal-hyprland;
    };

    xdg.portal.config.hyprland."org.freedesktop.impl.portal.Secret" = "gnome-keyring";
  };
}
