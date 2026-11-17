{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.features.system-base.enable {
    systemd.oomd = {
      enable = lib.mkDefault true;
      enableRootSlice = lib.mkDefault true;
      enableUserSlices = lib.mkDefault true;
    };

    zramSwap = {
      enable = lib.mkDefault true;
      algorithm = lib.mkDefault "zstd";
      memoryPercent = lib.mkDefault 25;
      priority = lib.mkDefault 100;
    };
  };
}
