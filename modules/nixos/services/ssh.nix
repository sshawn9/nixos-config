{
  lib,
  pkgs,
  ...
}:
{
  services.openssh = {
    enable = lib.mkDefault true;
    package = pkgs.unstable.openssh;
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}
