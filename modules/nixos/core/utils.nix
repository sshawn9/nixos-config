{ lib, ... }:

{
  services.udisks2.enable = lib.mkDefault true;

  services.gvfs.enable = lib.mkDefault true;

  services.power-profiles-daemon.enable = lib.mkDefault true;

  services.cpupower-gui.enable = lib.mkDefault true;
}
