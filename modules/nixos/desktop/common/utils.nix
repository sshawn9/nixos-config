{
  lib,
  ...
}:

{
  # Screenpipe uses AT-SPI2 to read the accessibility tree for paired UI
  # capture. This provides org.a11y.Bus in standalone Wayland sessions.
  services.gnome.at-spi2-core.enable = lib.mkDefault true;

  services.upower.enable = lib.mkDefault true;

  services.gnome.gnome-keyring.enable = lib.mkDefault true;

  hardware.bluetooth.enable = lib.mkDefault true;
  hardware.i2c.enable = lib.mkDefault true;
}
