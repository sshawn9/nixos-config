{
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs.unstable; [
    # Secret tooling
    libsecret

    # Clipboard
    wl-clipboard

    # Screenshot & screen recording
    flameshot
    kooha

    # Utilities
    xdg-utils
    xdg-user-dirs
    playerctl

    # Brightness control
    brightnessctl
    ddcutil

    # File manager
    nautilus

    # GTK3 theme
    adw-gtk3
  ];

  programs = {
    dconf.enable = lib.mkDefault true;

    xwayland.enable = lib.mkDefault true;

    gpu-screen-recorder = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.gpu-screen-recorder;

      ui = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.gpu-screen-recorder-ui;
        notifPackage = lib.mkDefault pkgs.unstable.gpu-screen-recorder-notification;
      };
    };
  };
}
