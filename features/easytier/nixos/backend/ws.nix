{
  config,
  lib,
  pkgs,
  ...
}:
let
  backend = config.features.easytier.backend.ws;
in
{
  config = lib.mkIf (config.features.easytier.enable && config.features.easytier.backend.ws.enable) {
    systemd.services.easytier-web-ws = {
      description = "EasyTier Web WS/WSS backend";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs [
          "${pkgs.unstable.easytier}/bin/easytier-web"
          "--db"
          "/var/lib/easytier-web-ws/et.db"
          "--api-server-addr"
          "127.0.0.1"
          "--api-server-port"
          (toString backend.apiPort)
          # Caddy terminates public WSS; the native configuration listener uses WS.
          "--config-server-protocol"
          "ws"
          "--config-server-port"
          (toString backend.configPort)
        ];
        EnvironmentFile = lib.optional (backend.environmentFile != null) backend.environmentFile;
        DynamicUser = true;
        StateDirectory = "easytier-web-ws";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/easytier-web-ws";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf config.systemd.services.easytier-web-ws.enable [
      backend.configPort
    ];

    services.caddy.virtualHosts = {
      ${toString backend.apiDomain}.extraConfig =
        lib.mkIf config.systemd.services.easytier-web-ws.enable ''
          reverse_proxy 127.0.0.1:${toString backend.apiPort}
        '';

      ${toString backend.wssDomain}.extraConfig =
        lib.mkIf config.systemd.services.easytier-web-ws.enable ''
          reverse_proxy 127.0.0.1:${toString backend.configPort}
        '';
    };
  };
}
