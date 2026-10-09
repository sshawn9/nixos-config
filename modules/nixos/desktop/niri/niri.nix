{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.my.shared.desktop.niri.enable {
    programs.niri = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.niri;
    };

    environment.systemPackages = [
      # Niri XWayland bridge
      pkgs.unstable.xwayland-satellite
    ];

    xdg.portal = {
      extraPortals = [ pkgs.unstable.xdg-desktop-portal-wlr ];
      # Capture multiple outputs without depending on Niri's screenshot directory.
      config.niri."org.freedesktop.impl.portal.Screenshot" = "wlr";
    };

    # LocalSearch checks XDG_SESSION_CLASS in the user manager environment.
    # Restore the value removed by greetd before starting the desktop.
    systemd.user.services.niri = {
      environment.XDG_SESSION_CLASS = "user";
      serviceConfig.ExecStartPre = [
        "${lib.getExe' pkgs.dbus "dbus-update-activation-environment"} --systemd XDG_SESSION_CLASS"
      ];
    };
  };
}
