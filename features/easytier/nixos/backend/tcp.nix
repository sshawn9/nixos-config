{
  config,
  lib,
  pkgs,
  ...
}:
let
  backend = config.features.easytier.backend.tcp;
in
{
  config = lib.mkIf (config.features.easytier.enable && config.features.easytier.backend.tcp.enable) {
    systemd.services.easytier-web-tcp = {
      description = "EasyTier Web TCP backend";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs [
          "${pkgs.unstable.easytier}/bin/easytier-web"
          "--db"
          "/var/lib/easytier-web-tcp/et.db"
          "--api-server-addr"
          "127.0.0.1"
          "--api-server-port"
          (toString backend.apiPort)
          "--config-server-protocol"
          "tcp"
          "--config-server-port"
          (toString backend.configPort)
        ];
        EnvironmentFile = lib.optional (backend.environmentFile != null) backend.environmentFile;
        DynamicUser = true;
        StateDirectory = "easytier-web-tcp";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/easytier-web-tcp";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf config.systemd.services.easytier-web-tcp.enable [
      backend.configPort
    ];

    services.caddy.virtualHosts.${toString backend.apiDomain}.extraConfig =
      lib.mkIf config.systemd.services.easytier-web-tcp.enable ''
        reverse_proxy 127.0.0.1:${toString backend.apiPort}
      '';
  };
}
