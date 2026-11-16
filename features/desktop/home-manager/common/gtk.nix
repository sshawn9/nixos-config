{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.desktop.enable {
    catppuccin.gtk.icon.enable = lib.mkDefault config.gtk.enable;

    gtk = {
      enable = lib.mkDefault true;
      theme = {
        name = lib.mkDefault "adw-gtk3-dark";
        package = lib.mkDefault pkgs.unstable.adw-gtk3;
      };
      # adw-gtk3 has no GTK2 theme and must not override libadwaita's GTK4 CSS.
      gtk2.theme = lib.mkDefault null;
      gtk4.theme = lib.mkDefault null;
    };
  };
}
