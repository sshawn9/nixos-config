{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktops.gnome.enable {
    services = {
      displayManager.gdm.enable = lib.mkDefault true;
      desktopManager.gnome.enable = lib.mkDefault true;
      gnome = {
        core-developer-tools.enable = lib.mkDefault false;
        games.enable = lib.mkDefault false;
      };
    };
    environment = {
      sessionVariables = {
        GTK_IM_MODULE = "fcitx";
      };
      gnome.excludePackages = with pkgs; [
        gnome-photos
        gnome-tour
        gnome-music
        epiphany
        geary
        totem
        yelp
        gnome-contacts
        gnome-maps
        simple-scan
      ];

      systemPackages = with pkgs; [
        unstable.gnomeExtensions.kimpanel
        unstable.gnomeExtensions.vitals
        unstable.gnomeExtensions.caffeine
        unstable.gnomeExtensions.dash-to-panel
      ];
    };
  };
}
