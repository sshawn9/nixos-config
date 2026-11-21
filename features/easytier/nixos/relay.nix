{
  config,
  lib,
  pkgs,
  ...
}:
let
  relayPort = config.features.easytier.relay.port;
in
{
  config = lib.mkIf (config.features.easytier.enable && config.features.easytier.relay.enable) {
    services.easytier = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.easytier;

      instances.relay = {
        # EasyTier 2.7.1+: use one multithreaded runtime with the available CPU count.
        extraArgs = [
          "--shared-runtime"
          # A numeric listener replaces the TOML list and expands all seven protocols.
          "--listeners"
          (toString relayPort)
        ];

        # Clients choose KCP/QUIC; the shared relay must allow their packets.
        extraSettings.flags = {
          enable_relay_foreign_network_kcp = lib.mkDefault true;
          enable_relay_foreign_network_quic = lib.mkDefault true;
        };
      };
    };

    systemd.services =
      lib.mkIf (config.services.easytier.enable && config.services.easytier.instances.relay.enable)
        {
          easytier-relay.serviceConfig.LimitNOFILE = lib.mkDefault 1048576;
        };

    networking.firewall = lib.mkIf (config.systemd.services.easytier-relay.enable or false) {
      # TCP, WS, WSS, FakeTCP.
      allowedTCPPorts = [
        relayPort
        (relayPort + 1)
        (relayPort + 2)
        (relayPort + 3)
      ];
      # UDP, WireGuard, QUIC.
      allowedUDPPorts = [
        relayPort
        (relayPort + 1)
        (relayPort + 2)
      ];
    };
  };
}
