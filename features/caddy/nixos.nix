{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  service = config.services.caddy;
  primaryUser = config.common.primaryUser;
  primaryUserConfig = config.home-manager.users.${primaryUser};
  caddyDirectory = "${primaryUserConfig.xdg.configHome}/caddy";
  caddySource = primaryUserConfig.lib.fileSources.local.xdgConfig.resolve "caddy";
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.caddy.enable (
    lib.mkMerge [
      {
        services.caddy = {
          enable = lib.mkDefault true;
          package = lib.mkDefault pkgs.unstable.caddy;
          openFirewall = lib.mkDefault true;
        };
      }
      (lib.mkIf (service.enable && primaryUser != null) {
        services.caddy = {
          globalConfig = lib.mkMerge [
            (lib.mkBefore ''
              import "${caddyDirectory}/*.global-before.caddy"
            '')
            (lib.mkAfter ''
              import "${caddyDirectory}/*.global-after.caddy"
            '')
          ];

          extraConfig = lib.mkMerge [
            (lib.mkBefore ''
              import "${caddyDirectory}/*.extra-before.caddy"
            '')
            (lib.mkAfter ''
              import "${caddyDirectory}/*.extra-after.caddy"
            '')
          ];
        };

        users.users.${primaryUser}.extraGroups = [ service.group ];

        systemd.services.caddy = {
          after = [ "home-manager-${utils.escapeSystemdPath primaryUser}.service" ];
          serviceConfig = {
            ProtectHome = lib.mkForce "tmpfs";
            BindReadOnlyPaths = [ caddyDirectory ] ++ caddySource.localDirectories;
          };
        };
      })
    ]
  );
}
