{
  config,
  lib,
  pkgs,
  ...
}:
let
  service = config.services.caddy;
  primaryUser = config.common.primaryUser;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.caddy.enable {
    services.caddy = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.caddy;
      openFirewall = lib.mkDefault true;
    };

    users.users = lib.mkIf (service.enable && primaryUser != null) {
      ${primaryUser}.extraGroups = [ service.group ];
    };
  };
}
