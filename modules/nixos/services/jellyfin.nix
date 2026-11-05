{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.jellyfin;
  nvidia = config.my.shared.nvidia.enable;
  username = config.my.shared.username;
  user = config.users.users.${username};
in
{
  services.jellyfin = {
    enable = lib.mkDefault false;
    package = lib.mkDefault pkgs.unstable.jellyfin;
    user = lib.mkDefault username;
    group = lib.mkDefault user.group;
    openFirewall = lib.mkDefault true;

    hardwareAcceleration = lib.mkIf nvidia {
      enable = lib.mkDefault true;
      type = lib.mkDefault "nvenc";
      device = lib.mkDefault "/dev/dri/renderD128";
    };

    transcoding = lib.mkIf nvidia {
      enableHardwareEncoding = lib.mkDefault true;
      hardwareDecodingCodecs = {
        av1 = lib.mkDefault true;
        h264 = lib.mkDefault true;
        hevc = lib.mkDefault true;
        hevc10bit = lib.mkDefault true;
        mpeg2 = lib.mkDefault true;
        vp8 = lib.mkDefault true;
        vp9 = lib.mkDefault true;
      };
    };
  };

  systemd.services.jellyfin = lib.mkIf cfg.enable {
    serviceConfig = {
      ProtectHome = "tmpfs";
      # Keep normal user permissions for the originals, while only exposing these
      # directories inside the service's otherwise hidden home filesystem.
      BindReadOnlyPaths = [
        "${user.home}/Videos"
        "${user.home}/Music"
      ];

      # The upstream module only allows hardwareAcceleration.device, but NVENC also
      # needs the NVIDIA character devices.
      DeviceAllow = lib.mkIf nvidia [
        "char-nvidia rw"
        "char-nvidia-uvm rw"
      ];
    };
  };
}
