{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.container.enable {
    virtualisation.waydroid = {
      enable = lib.mkDefault false;
      package = lib.mkDefault (
        if config.networking.nftables.enable then
          pkgs.unstable.waydroid-nftables
        else
          pkgs.unstable.waydroid
      );
    };
  };
}
