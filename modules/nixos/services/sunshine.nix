{
  lib,
  config,
  pkgs,
  ...
}:

{
  services.sunshine = {
    enable = lib.mkDefault false;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    package = lib.mkDefault (
      pkgs.unstable.sunshine.override {
        cudaSupport = true;
      }
    );
  };

  users.users.${config.my.shared.username}.extraGroups = [
    "input"
    "video"
    "render"
  ];
}
