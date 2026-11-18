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

    boot = lib.mkIf config.zramSwap.enable {
      kernel.sysctl = {
        "vm.swappiness" = lib.mkDefault 100;
        "vm.page-cluster" = lib.mkDefault 0;
      };

      # Disable kernel-default zswap at boot and when switching configurations.
      kernelParams = [ "zswap.enabled=0" ];
      kernel.sysfs.module.zswap.parameters.enabled = lib.mkDefault false;
    };
  };
}
