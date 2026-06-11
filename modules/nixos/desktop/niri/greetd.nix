{
  config,
  lib,
  pkgs,
  ...
}:

let
  sessionDir = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";

  tuigreetCmd = lib.concatStringsSep " " [
    "${pkgs.unstable.tuigreet}/bin/tuigreet"
    "--time"
    "--time-format '%Y-%m-%d | %H:%M:%S'"
    "--greeting 'Welcome // NixOS'"
    "--asterisks"
    "--asterisks-char '•'"
    "--window-padding 2"
    "--container-padding 3"
    "--remember"
    "--remember-session"
    "--sessions ${sessionDir}"
  ];
in
{
  config = lib.mkIf config.my.shared.desktops.niri.enable {
    services.greetd = {
      enable = true;
      package = pkgs.unstable.greetd;
      useTextGreeter = true;
      settings = {
        default_session = {
          command = tuigreetCmd;
          user = "greeter";
        };
      };
    };

    # Suppress kernel/systemd boot messages to keep tuigreet screen clean
    # boot.consoleLogLevel = lib.mkDefault 3;
    # boot.kernelParams = [
    #   "quiet"
    #   "udev.log_priority=3"
    # ];
  };
}
