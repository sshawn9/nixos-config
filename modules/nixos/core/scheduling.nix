{
  lib,
  pkgs,
  ...
}:

{
  services.scx-loader = {
    enable = lib.mkDefault true;
    schedsPackages = lib.mkDefault [ pkgs.scx.full ];
    config.default_sched = lib.mkDefault "scx_lavd";
  };

  systemd = {
    oomd = {
      enable = lib.mkDefault true;
      enableRootSlice = lib.mkDefault true;
      enableUserSlices = lib.mkDefault true;
    };

    services.nix-daemon.serviceConfig = {
      CPUAccounting = lib.mkDefault true;
      IOAccounting = lib.mkDefault true;
      MemoryAccounting = lib.mkDefault true;
      TasksAccounting = lib.mkDefault true;

      # Cgroup weights are soft, not caps: Nix can still use idle resources,
      # while the desktop gets priority during contention.
      CPUWeight = lib.mkDefault 25;
      IOWeight = lib.mkDefault 25;
    };
  };

  zramSwap = {
    enable = lib.mkDefault true;
    algorithm = lib.mkDefault "zstd";
    memoryPercent = lib.mkDefault 25;
    priority = lib.mkDefault 100;
  };
}
