{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.container.enable {
    hardware.nvidia-container-toolkit = {
      enable = lib.mkDefault (
        (
          config.virtualisation.docker.enable
          || config.virtualisation.docker.rootless.enable
          || config.virtualisation.podman.enable
        )
        && config.hardware.nvidia.enabled
      );
      package = lib.mkDefault pkgs.unstable.nvidia-container-toolkit;
    };
  };
}
