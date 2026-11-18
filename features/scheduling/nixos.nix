{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.scheduling.enable {
    services.scx-loader = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.scx-loader;
      schedsPackages = lib.mkDefault [ pkgs.unstable.scx.full ];
      config.default_sched = lib.mkDefault "scx_lavd";
    };

    services.ananicy = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.ananicy-cpp;
      rulesProvider = lib.mkDefault pkgs.unstable.ananicy-rules-cachyos;

      settings = {
        # Leave CPU placement and cgroup management to SCX and systemd.
        cgroup_load = lib.mkDefault false;
        apply_cgroup = lib.mkDefault false;
        apply_cpuset = lib.mkDefault false;
        # NixOS assigns true directly, so mkDefault cannot override it.
        cgroup_realtime_workaround = lib.mkForce false;
      };
    };
  };
}
