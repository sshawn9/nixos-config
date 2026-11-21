{ config, lib, ... }:
let
  backends = lib.getAttrs [ "udp" "tcp" "ws" ] config.features.easytier.backend;
  backendDefault = config.features.easytier.backend.default;
  defaultBackendName = if backendDefault.type == "wss" then "ws" else backendDefault.type;
  selectedBackend = backends.${defaultBackendName};
  configServerUrl =
    if backendDefault.type == "wss" then
      "wss://${toString backendDefault.configDomain}"
    else
      "${backendDefault.type}://${toString backendDefault.configDomain}:${toString selectedBackend.configPort}";
  defaultApiAliases = lib.optional (
    selectedBackend.enable
    && backendDefault.apiDomain != null
    && backendDefault.apiDomain != selectedBackend.apiDomain
  ) backendDefault.apiDomain;
  enabledBackends = lib.filterAttrs (_: backend: backend.enable) backends;
  frontends = config.features.easytier.frontend;
  enabledFrontends = lib.filterAttrs (_: frontend: frontend.enable) (
    lib.getAttrs [ "udp" "tcp" "ws" ] frontends
  );
  tcpPorts = lib.concatLists (
    lib.mapAttrsToList (
      protocol: backend: [ backend.apiPort ] ++ lib.optional (protocol != "udp") backend.configPort
    ) enabledBackends
  );
  domains = lib.filter (domain: domain != null && domain != "") (
    map (backend: backend.apiDomain) (builtins.attrValues enabledBackends)
    ++ defaultApiAliases
    ++ lib.optional (backendDefault.configDomain != null) backendDefault.configDomain
    ++ map (frontend: frontend.domain) (builtins.attrValues enabledFrontends)
    ++ lib.optional (frontends.default.domain != null) frontends.default.domain
  );
in
{
  imports = [
    ./options.nix
    ./overlay.nix
    ./nixos/client.nix
    ./nixos/relay.nix
    ./nixos/backend/udp.nix
    ./nixos/backend/tcp.nix
    ./nixos/backend/ws.nix
    ./nixos/frontend.nix
  ];

  config = lib.mkIf config.features.easytier.enable {
    services.caddy.virtualHosts = lib.mkMerge [
      (lib.mkIf (defaultApiAliases != [ ]) {
        ${toString selectedBackend.apiDomain}.serverAliases = defaultApiAliases;
      })
      # Config Server 接入：将 configDomain 的 A/AAAA 记录指向后端服务器的公网 IP，使用仅 DNS 模式。
      # 统一地址：https://et-config.example.com/DEVICE_TOKEN，实际协议由 backend.default.type 选择。
      # 普通 HTTPS 请求取得默认连接地址；WebSocket 升级请求进入 WS 后端。
      # WSS：wss://et-config.example.com/DEVICE_TOKEN，经 Caddy 443 反代到 WS 后端。
      # 以下原生地址直接连接各自监听端口，不经过 Caddy：
      # UDP：udp://et-config.example.com:22020/DEVICE_TOKEN
      # TCP：tcp://et-config.example.com:22021/DEVICE_TOKEN
      # WS：ws://et-config.example.com:22022/DEVICE_TOKEN
      # 域名和 DEVICE_TOKEN 均为占位；端口为默认值，实际使用对应后端的 configPort。
      # 本 feature 不创建或修改 DNS 记录。
      (lib.mkIf (backendDefault.configDomain != null) {
        ${toString backendDefault.configDomain}.extraConfig = lib.mkMerge [
          (lib.mkIf (config.systemd.services.easytier-web-ws.enable or false) ''
            @websocket header Upgrade websocket
            handle @websocket {
              reverse_proxy 127.0.0.1:${toString backends.ws.configPort}
            }
          '')
          (lib.mkIf (config.systemd.services."easytier-web-${defaultBackendName}".enable or false) ''
            handle {
              header Cache-Control "no-store"
              respond ${builtins.toJSON configServerUrl} 200
            }
          '')
        ];
      })
    ];

    assertions =
      lib.mapAttrsToList (protocol: backend: {
        assertion = backend.apiDomain != null && backend.apiDomain != "";
        message = "features.easytier.backend.${protocol}.apiDomain must be set when that backend is enabled.";
      }) enabledBackends
      ++ [
        {
          assertion = !backends.ws.enable || backendDefault.configDomain != null;
          message = "features.easytier.backend.default.configDomain must be set when the WS/WSS backend is enabled.";
        }
        {
          assertion = backendDefault.configDomain == null || selectedBackend.enable;
          message = "The EasyTier backend selected by backend.default.type must be enabled when backend.default.configDomain is set.";
        }
        {
          assertion = builtins.length tcpPorts == builtins.length (lib.unique tcpPorts);
          message = "Enabled EasyTier API ports and TCP/WS configuration ports must be distinct.";
        }
        {
          assertion = builtins.length domains == builtins.length (lib.unique domains);
          message = "Enabled EasyTier API, Config Server and frontend hostnames must be distinct.";
        }
      ];
  };
}
