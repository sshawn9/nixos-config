{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktops.niri.enable {
    services.upower.enable = lib.mkDefault true;
    hardware.bluetooth.enable = lib.mkDefault true;
  };
}
