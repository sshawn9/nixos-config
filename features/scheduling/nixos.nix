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
  };
}
