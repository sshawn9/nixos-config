{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf (config.my.shared.desktop.active != [ ]) {
    catppuccin.cursors.enable = lib.mkDefault true;

    home.pointerCursor = {
      enable = lib.mkDefault true;
      gtk.enable = lib.mkDefault true;
      size = lib.mkDefault config.my.shared.cursor.size;
    };
  };
}
