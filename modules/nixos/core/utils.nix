{ config, lib, ... }:

{
  services.udisks2.enable = lib.mkDefault true;

  services.gvfs.enable = lib.mkDefault true;

  services.power-profiles-daemon.enable = lib.mkDefault true;

  security.sudo.extraConfig = ''
    Defaults:${config.my.shared.username} noninteractive_auth
  '';

  security.polkit.enable = lib.mkDefault true;
  security.polkit.enablePkexecWrapper = lib.mkDefault true;
}
