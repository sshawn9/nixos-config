{
  config,
  lib,
  pkgs,
  ...
}:
let
  primaryUserConfig = config.home-manager.users.${config.common.primaryUser};
  caddySource = primaryUserConfig.lib.fileSources.local.xdgConfig.resolve "caddy";
in
{
  config = lib.mkIf config.services.caddy.enable {
    services.caddy = {
      package = pkgs.unstable.caddy.withPlugins {
        plugins = [ "github.com/mholt/caddy-l4@v0.1.3" ];
        hash = "sha256-N4LqqEcmChyzsTBSC0/6htPYyLoAi15mMaTm7djgEYs=";
      };
      configFile = pkgs.writeText "Caddyfile" ''
        import /run/caddy-config/Caddyfile
      '';
    };

    systemd.services.caddy.environment = {
      REALITY_SITE_ROOT = "${./reality/site}";
    };

    systemd.services.caddy.serviceConfig = {
      ProtectHome = lib.mkForce "tmpfs";
      BindReadOnlyPaths = [
        "${caddySource.source}:/run/caddy-config"
      ]
      ++ caddySource.localDirectories;
    };
  };
}
