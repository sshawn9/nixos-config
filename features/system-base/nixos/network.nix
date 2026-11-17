{ config, lib, ... }:
{
  config = lib.mkIf config.features.system-base.enable {
    networking.networkmanager.enable = lib.mkDefault true;

    users.users =
      lib.mkIf (config.networking.networkmanager.enable && config.common.primaryUser != null)
        {
          ${config.common.primaryUser}.extraGroups = [ "networkmanager" ];
        };
  };
}
