{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf (config.my.shared.desktop.active != [ ]) {
    # The Catppuccin GTK theme port is archived; this sub-module only
    # provides the Papirus-derived Catppuccin icon set.
    catppuccin.gtk.icon.enable = lib.mkDefault true;

    gtk = {
      enable = lib.mkDefault true;

      # GTK3's Adwaita ignores the color-scheme preference that libadwaita
      # follows, so GTK3 apps stayed light next to dark libadwaita apps.
      # adw-gtk3-dark gives GTK3 the same dark look.
      theme = {
        name = lib.mkDefault "adw-gtk3-dark";
        package = lib.mkDefault pkgs.unstable.adw-gtk3;
      };

      # Keep adw-gtk3 out of gtk-4.0/gtk.css, which Home Manager otherwise
      # writes before home.stateVersion 26.05 by reusing gtk.theme here and
      # which would override libadwaita apps too. libadwaita keeps its own
      # stylesheet and follows color-scheme; plain GTK4 apps still pick up
      # adw-gtk3-dark from the gtk-theme dconf key.
      gtk4.theme = null;

      # adw-gtk3 ships no GTK2 theme, so keep its name out of .gtkrc-2.0.
      gtk2.theme = null;
    };
  };
}
