{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.cachyos-kernel.enable {
    boot.kernelPackages = lib.mkDefault inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages-cachyos-bore-lto-x86_64-v3;

    boot.kernelModules = [
      "tcp_bbr3"
      "sch_fq"
    ];

    boot.kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = lib.mkDefault "bbr3";
      "net.core.default_qdisc" = lib.mkDefault "fq";
    };

    nix.settings = {
      extra-substituters = [ "https://cache.lantian.pub/lantian" ];
      extra-trusted-public-keys = [
        "lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="
      ];
    };
  };
}
