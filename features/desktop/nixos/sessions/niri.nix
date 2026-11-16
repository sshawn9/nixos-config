{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.features.desktop.enable && config.features.desktop.niri.enable) {
    programs.niri = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.niri;
    };

    environment.systemPackages = [ pkgs.unstable.xwayland-satellite ];

    xdg.portal = {
      extraPortals = [ pkgs.unstable.xdg-desktop-portal-wlr ];
      config.niri."org.freedesktop.impl.portal.Screenshot" = "wlr";
    };

    # greetd removes this variable after PAM; LocalSearch needs it in the user manager.
    systemd.user.services.niri = {
      environment.XDG_SESSION_CLASS = "user";
      serviceConfig.ExecStartPre = [
        "${lib.getExe' pkgs.unstable.dbus "dbus-update-activation-environment"} --systemd XDG_SESSION_CLASS"
      ];
    };
  };
}
