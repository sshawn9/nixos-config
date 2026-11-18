{ config, lib, ... }:
{
  config = lib.mkIf config.features.programs.enable {
    package = {
      wget = lib.mkDefault true;
      sshpass = lib.mkDefault true;
      nettools = lib.mkDefault true;
      socat = lib.mkDefault true;
      whois = lib.mkDefault true;
      nmap = lib.mkDefault true;
      dnsutils = lib.mkDefault true;
      xh = lib.mkDefault true;
      mtr = lib.mkDefault true;
      sshfs = lib.mkDefault true;
      tcpdump = lib.mkDefault true;
      remmina = lib.mkDefault false;
    };
  };
}
