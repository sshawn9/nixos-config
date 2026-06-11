{
  inputs,
  pkgs,
  lib,
  ...
}:

{
  nix.settings.extra-substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.extra-trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-x86_64-v3;

  boot.kernelModules = [
    "tcp_bbr3"
    "sch_fq"
  ];

  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr3";
    "net.core.default_qdisc" = "fq";

    "vm.swappiness" = lib.mkDefault 100;
    "vm.page-cluster" = lib.mkDefault 0;
    "vm.vfs_cache_pressure" = lib.mkDefault 50;

    "vm.dirty_bytes" = lib.mkDefault 268435456;
    "vm.dirty_background_bytes" = lib.mkDefault 67108864;
    "vm.dirty_writeback_centisecs" = lib.mkDefault 1500;

    "kernel.nmi_watchdog" = 0;
  };

  boot.kernel.sysfs = {
    kernel.mm.transparent_hugepage.defrag = lib.mkDefault "defer+madvise";
    module.zswap.parameters.enabled = false;
  };

  boot.kernelParams = [ "zswap.enabled=0" ];

  services.ananicy = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.unstable.ananicy-cpp;
    rulesProvider = lib.mkDefault pkgs.ananicy-rules-cachyos;

    settings = {
      # Let scx_lavd and systemd own CPU placement/cgroup policy.
      cgroup_load = lib.mkDefault false;
      apply_cgroup = lib.mkDefault false;
      cgroup_realtime_workaround = lib.mkDefault false;
      apply_cpuset = lib.mkDefault false;
    };
  };
}
