{
  config,
  lib,
  ...
}:
let
  inherit (config.lib.fileSources.local.xdgConfig) link;
  caddyExe = lib.getExe config.package.caddy.package;
  caddyfile = "${config.xdg.configHome}/caddy/Caddyfile";
  configArgs = "--config ${lib.escapeShellArg caddyfile} --adapter caddyfile";
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.caddy.enable {
    package.caddy = lib.mkDefault true;

    xdg.configFile."caddy/Caddyfile" = link "caddy/Caddyfile";

    systemd.user.services.caddy = {
      Unit.Description = "Caddy web server";
      Service = {
        Type = "notify";
        ExecStart = "${caddyExe} run ${configArgs}";
        ExecReload = "${caddyExe} reload ${configArgs} --force";
        Restart = "on-failure";
        Environment = [
          "XDG_CONFIG_HOME=${config.xdg.configHome}"
          "XDG_DATA_HOME=${config.xdg.dataHome}"
        ];
      };
      # Install.WantedBy = [ "default.target" ];
    };
  };
}
