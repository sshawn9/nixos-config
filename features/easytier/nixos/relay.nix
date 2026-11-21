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

      # 手动运行同等中转功能（EasyTier 2.7.1+，默认端口 11010）：
      # sudo easytier-core \
      #   --instance-name relay \
      #   --shared-runtime \
      #   --listeners 11010 \
      #   --enable-relay-foreign-network-kcp true \
      #   --enable-relay-foreign-network-quic true
      # 自定义 relay.port 时同步替换 --listeners；同机运行时避免与现有中转服务占用相同端口。
      # 文件描述符上限由下方 systemd 的 LimitNOFILE 设置，手动运行时由启动环境单独设置。
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
