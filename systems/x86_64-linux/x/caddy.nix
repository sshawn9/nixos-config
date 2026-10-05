{ config, lib, ... }:
let
  homeDir = config.users.users.${config.my.shared.username}.home;
  caddyDir = "${homeDir}/ghq/github.com/sshawn9/nixos-config/.dotfiles/x/etc/caddy";
in
{
  services.caddy.configFile = "${caddyDir}/Caddyfile";

  systemd.services.caddy = lib.mkIf config.services.caddy.enable {
    serviceConfig = {
      ProtectHome = lib.mkForce "tmpfs";
      BindReadOnlyPaths = [ caddyDir ];
    };
  };
}
