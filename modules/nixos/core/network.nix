{
  config,
  lib,
  ...
}:

{
  networking.hostName = config.my.shared.hostname;
  networking.networkmanager.enable = lib.mkDefault true;

  users.users.${config.my.shared.username}.extraGroups = [ "networkmanager" ];

  networking.firewall = {
    allowedTCPPorts = [ 29102 ];
    allowedUDPPorts = [ 29102 ];
  };
}
