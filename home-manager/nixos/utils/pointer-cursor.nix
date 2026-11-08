{
  config,
  lib,
  ...
}:

{
  home.pointerCursor = {
    enable = lib.mkDefault true;
    gtk.enable = lib.mkDefault true;
    size = lib.mkDefault config.my.shared.cursor.size;
  };
}
