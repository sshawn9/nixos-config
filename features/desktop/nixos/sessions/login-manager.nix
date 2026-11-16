{
  config,
  lib,
  pkgs,
  ...
}:
let
  sessionDir = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
  command = lib.concatStringsSep " " [
    "${lib.getExe pkgs.unstable.tuigreet}"
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
    # Remembered store paths can expire after a rebuild.
    (lib.optionalString config.features.desktop.niri.enable "--cmd ${config.programs.niri.package}/bin/niri-session")
  ];
in
{
  config = lib.mkIf config.features.desktop.enable {
    services.greetd = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.greetd;
      useTextGreeter = lib.mkDefault true;
      settings.default_session = {
        inherit command;
        user = "greeter";
      };
    };
  };
}
