{
  config,
  lib,
  myLib,
  specialArgs,
  ...
}@args:
let
  # Embedded in NixOS, follow whether the system enables the
  # gpu-screen-recorder UI. Standalone Home Manager has no system config to
  # read, so fall back to whether the host has a desktop.
  enable =
    if myLib.inNixOSSystem args then
      specialArgs.osConfig.programs.gpu-screen-recorder.ui.enable
    else
      config.my.shared.desktop.active != [ ];
in
{
  config = lib.mkIf enable {
    xdg.configFile."gpu-screen-recorder/config_ui".source =
      config.my.paths.local.xdgConfigLayeredSource "gpu-screen-recorder/config_ui";
  };
}
