{ config, lib, ... }:
{
  config = lib.mkIf config.features.desktop.enable {
    services = {
      gnome.at-spi2-core.enable = lib.mkDefault true;
      gnome.gnome-keyring.enable = lib.mkDefault true;
      upower.enable = lib.mkDefault true;
      udisks2.enable = lib.mkDefault true;
      gvfs.enable = lib.mkDefault true;
      power-profiles-daemon.enable = lib.mkDefault true;
      printing.enable = lib.mkDefault true;
    };
    security.polkit.enable = lib.mkDefault true;
    security.polkit.enablePkexecWrapper = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
    hardware.i2c.enable = lib.mkDefault true;
    xdg.portal = {
      enable = lib.mkDefault true;
      xdgOpenUsePortal = lib.mkDefault true;
    };
  };
}
