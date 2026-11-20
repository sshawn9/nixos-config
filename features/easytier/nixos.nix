{ config, lib, ... }:
let
  backends = config.features.easytier.backend;
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
    ++ lib.optional backends.ws.enable backends.ws.wssDomain
    ++ map (frontend: frontend.domain) (builtins.attrValues enabledFrontends)
    ++ lib.optional (frontends.default.domain != null) frontends.default.domain
  );
in
{
  imports = [
    ./options.nix
    ./nixos/backend/udp.nix
    ./nixos/backend/tcp.nix
    ./nixos/backend/ws.nix
    ./nixos/frontend.nix
  ];

  config = lib.mkIf config.features.easytier.enable {
    assertions =
      lib.mapAttrsToList (protocol: backend: {
        assertion = backend.apiDomain != null && backend.apiDomain != "";
        message = "features.easytier.backend.${protocol}.apiDomain must be set when that backend is enabled.";
      }) enabledBackends
      ++ [
        {
          assertion = frontends.default.domain == null || frontends.${frontends.default.type}.enable;
          message = "features.easytier.frontend.${frontends.default.type}.enable must be true when frontend.default.domain is set.";
        }
        {
          assertion = !backends.ws.enable || (backends.ws.wssDomain != null && backends.ws.wssDomain != "");
          message = "features.easytier.backend.ws.wssDomain must be set when the WS/WSS backend is enabled.";
        }
        {
          assertion = builtins.length tcpPorts == builtins.length (lib.unique tcpPorts);
          message = "Enabled EasyTier API ports and TCP/WS configuration ports must be distinct.";
        }
        {
          assertion = builtins.length domains == builtins.length (lib.unique domains);
          message = "Enabled EasyTier API, WSS and frontend hostnames must be distinct.";
        }
      ];
  };
}
