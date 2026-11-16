{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.nvidia.enable {
    nix.settings = {
      extra-substituters = [ "https://cache.nixos-cuda.org" ];
      extra-trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      ];
    };

    services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];

    hardware = {
      graphics = {
        enable = lib.mkDefault true;
        enable32Bit = lib.mkDefault pkgs.stdenv.hostPlatform.isx86_64;
      };

      nvidia = {
        modesetting.enable = lib.mkDefault true;
        dynamicBoost.enable = lib.mkDefault true;
        powerManagement.enable = lib.mkDefault true;
        open = lib.mkDefault true;
        nvidiaPersistenced = lib.mkDefault true;
      };
    };

    environment.sessionVariables = lib.mkIf config.hardware.nvidia.videoAcceleration {
      LIBVA_DRIVER_NAME = lib.mkDefault "nvidia";
    };
  };
}
