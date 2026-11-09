{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking.firewall = lib.mkIf config.services.caddy.enable {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [ 443 ];
  };

  services.caddy = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.unstable.caddy;
  };

  users.users.${config.my.shared.username}.extraGroups = lib.mkIf config.services.caddy.enable [
    "caddy"
  ];
}
