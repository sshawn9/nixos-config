{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.system-tuning.enable {
    boot.kernelPackages =
      lib.mkDefault
        inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages-cachyos-bore-lto-x86_64-v3;

    boot.kernelModules = [
      "tcp_bbr3"
      "sch_fq"
    ];

    boot.kernel.sysctl = {
      "kernel.sched_bore" = lib.mkDefault 1;
      "net.ipv4.tcp_congestion_control" = lib.mkDefault "bbr3";
      "net.core.default_qdisc" = lib.mkDefault "fq";
    };

    services.ananicy = {
      # BORE 已按任务行为调整调度权重；叠加 Ananicy 规则可能过度调整优先级，
      # 上游曾报告由此导致游戏卡顿。通用规则的进程分类也未必符合实际负载，
      # 因此默认关闭，仅在明确需要这些优先级策略时启用。
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.ananicy-cpp;
      rulesProvider = lib.mkDefault pkgs.unstable.ananicy-rules-cachyos;

      settings = {
        # Leave CPU placement and cgroup management to the kernel and systemd.
        cgroup_load = lib.mkDefault false;
        apply_cgroup = lib.mkDefault false;
        apply_cpuset = lib.mkDefault false;
        # NixOS assigns true directly, so mkDefault cannot override it.
        cgroup_realtime_workaround = lib.mkForce false;
      };
    };

    nix.settings = {
      extra-substituters = [ "https://cache.lantian.pub/lantian" ];
      extra-trusted-public-keys = [
        "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
      ];
    };
  };
}
