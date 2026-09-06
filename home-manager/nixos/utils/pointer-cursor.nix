{
  lib,
  ...
}:

{
  home.pointerCursor = {
    enable = lib.mkDefault true;
    gtk.enable = lib.mkDefault true;
    size = lib.mkDefault 32;
  };
}
