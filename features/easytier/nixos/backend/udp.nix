{
  config,
  lib,
  pkgs,
  ...
}:
let
  backend = config.features.easytier.backend.udp;
in
{
  config = lib.mkIf (config.features.easytier.enable && config.features.easytier.backend.udp.enable) {
    systemd.services.easytier-web-udp = {
      description = "EasyTier Web UDP backend";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs [
          "${pkgs.unstable.easytier}/bin/easytier-web"
          "--db"
          "/var/lib/easytier-web-udp/et.db"
          "--api-server-addr"
          "127.0.0.1"
          "--api-server-port"
          (toString backend.apiPort)
          "--config-server-protocol"
          "udp"
          "--config-server-port"
          (toString backend.configPort)
        ];
        EnvironmentFile = lib.optional (backend.environmentFile != null) backend.environmentFile;
        DynamicUser = true;
        StateDirectory = "easytier-web-udp";
        StateDirectoryMode = "0700";
        WorkingDirectory = "/var/lib/easytier-web-udp";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    networking.firewall.allowedUDPPorts = lib.mkIf config.systemd.services.easytier-web-udp.enable [
      backend.configPort
    ];

    services.caddy.virtualHosts.${toString backend.apiDomain}.extraConfig =
      lib.mkIf config.systemd.services.easytier-web-udp.enable ''
        reverse_proxy 127.0.0.1:${toString backend.apiPort}
      '';
  };
}
