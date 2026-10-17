# Fetch Waydroid images.
# You can add the parameters "-s GAPPS -f" to have GApps support.
# $ sudo waydroid init
# https://wiki.nixos.org/wiki/Waydroid

{
  config,
  lib,
  pkgs,
  ...
}:

{
  virtualisation = {
    waydroid = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.waydroid-nftables;
    };
  };

  home-manager.users.${config.my.shared.username} =
    {
      config,
      lib,
      osConfig,
      ...
    }:
    {
      systemd.user.tmpfiles.rules = lib.mkIf (!osConfig.virtualisation.waydroid.enable) [
        "r ${builtins.toJSON "${config.xdg.dataHome}/applications/waydroid.*.desktop"} - - - -"
      ];
    };
}
