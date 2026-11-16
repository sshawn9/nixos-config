{ config, lib, ... }:
{
  config = lib.mkIf config.features.desktop.enable {
    # The port supplies name/package; pointerCursor.enable controls their application.
    catppuccin.cursors.enable = lib.mkDefault true;
    home.pointerCursor = {
      enable = lib.mkDefault true;
      gtk.enable = lib.mkDefault config.gtk.enable;
      size = lib.mkDefault config.features.desktop.cursor.size;
    };
  };
}
