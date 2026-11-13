{ config, ... }:
{
  # The same peer port the Home Manager half seeds.
  networking.firewall = {
    allowedTCPPorts = [ config.features.qbittorrent.peerPort ];
    allowedUDPPorts = [ config.features.qbittorrent.peerPort ];
  };
}
