{ config, lib, ... }:

{
  sops.secrets.cloudflared_x_token = {
    restartUnits = [ "cloudflared-tunnel-x.service" ];
  };

  services.cloudflared = {
    enable = true;
    tunnels.x = {
      credentialsFile = config.sops.secrets.cloudflared_x_token.path;
      # Required by upstream; token mode uses routing from the Cloudflare dashboard.
      default = "http_status:404";
    };
  };

  systemd.services.cloudflared-tunnel-x = {
    serviceConfig = {
      ExecStart = lib.mkForce (
        "${config.services.cloudflared.package}/bin/cloudflared"
        + " tunnel --no-autoupdate run --token-file %d/credentials.json"
      );
      RestartSec = "5s";
    };
  };
}
