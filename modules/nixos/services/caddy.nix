{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
  networking.firewall.allowedUDPPorts = [ 443 ];

  services.caddy = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.unstable.caddy;
  };

  users.users.${config.my.shared.username}.extraGroups = [ "caddy" ];
}
