{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.services.caddy;
  caddy = lib.getExe pkgs.unstable.caddy;
  caddyfile = "${config.xdg.configHome}/caddy/Caddyfile";
in
{
  options.my.services.caddy.enable = lib.mkEnableOption "user-level Caddy web server";

  config = lib.mkIf cfg.enable {
    xdg.configFile."caddy/Caddyfile".source =
      config.my.paths.local.xdgConfigLayeredSource "caddy/Caddyfile";

    systemd.user.services.caddy = {
      Unit.Description = "Caddy web server";
      Service = {
        Type = "notify";
        ExecStart = "${caddy} run --config ${caddyfile} --adapter caddyfile";
        ExecReload = "${caddy} reload --config ${caddyfile} --adapter caddyfile --force";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
