{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktops.niri.enable {
    # ── Wayland base infrastructure ──
    programs.dconf.enable = lib.mkDefault true;

    # Screenpipe uses AT-SPI2 to read the accessibility tree for paired UI
    # capture. This provides org.a11y.Bus in the user DBus session under niri.
    services.gnome.at-spi2-core.enable = lib.mkDefault true;

    programs.xwayland.enable = lib.mkDefault true;
  };
}
