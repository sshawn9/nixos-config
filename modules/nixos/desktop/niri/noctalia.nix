{
  config,
  lib,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktops.niri.enable {
    services.upower.enable = true;
    hardware.bluetooth.enable = true;
  };
}
