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
    "--remember-user-session"
    "--sessions ${sessionDir}"
    # Fall back to niri when the remembered session's store path has changed.
    (lib.optionalString config.programs.niri.enable "--cmd ${config.programs.niri.package}/bin/niri-session")
  ];
in
{
  config = lib.mkIf (config.my.shared.desktop.active != [ ]) {
    services.greetd = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.greetd;
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
