{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.programs.enable {
    programs.gpu-screen-recorder = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.gpu-screen-recorder;
      ui = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.unstable.gpu-screen-recorder-ui;
        notifPackage = lib.mkDefault pkgs.unstable.gpu-screen-recorder-notification;
      };
    };
  };
}
