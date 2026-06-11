{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktops.niri.enable {
    programs.gpu-screen-recorder = {
      enable = true;
      package = pkgs.unstable.gpu-screen-recorder;
    };

    environment.systemPackages = with pkgs.unstable; [
      # Secret tooling
      libsecret

      # Clipboard
      wl-clipboard

      # Screenshot & screen recording
      grim
      slurp
      satty
      kooha
      gpu-screen-recorder-gtk

      # Utilities
      xdg-utils

      # Brightness control
      brightnessctl

      # File manager
      nautilus

      # Niri XWayland bridge
      xwayland-satellite
    ];
  };
}
