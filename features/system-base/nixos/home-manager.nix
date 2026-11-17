{ config, lib, ... }:
{
  config = lib.mkIf config.features.system-base.enable {
    home-manager.backupFileExtension = lib.mkDefault "hm-backup";
  };
}
