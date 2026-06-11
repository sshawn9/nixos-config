{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.nvidia.enable {
    # boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

    # boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];

    services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = lib.mkDefault "nvidia";
      # EGL_PLATFORM = "wayland";
    };

    hardware = {
      graphics = {
        enable = lib.mkDefault true;
        enable32Bit = lib.mkDefault true;
        # extraPackages = with pkgs; [
        #   # intel-media-driver
        # ];
      };

      nvidia = {
        # package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
        modesetting.enable = lib.mkDefault true;
        dynamicBoost.enable = lib.mkDefault false;
        powerManagement.enable = lib.mkDefault true;
        powerManagement.finegrained = lib.mkDefault false;
        open = lib.mkDefault true;
        nvidiaSettings = lib.mkDefault true;
        videoAcceleration = lib.mkDefault true;
        nvidiaPersistenced = lib.mkDefault true;
        forceFullCompositionPipeline = lib.mkDefault false;
      };

      nvidia-container-toolkit = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.nvidia-container-toolkit;
      };
    };
  };
}
