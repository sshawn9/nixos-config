{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.features.system-base.enable {
    boot.loader = {
      timeout = lib.mkDefault 2;
      systemd-boot = {
        configurationLimit = lib.mkDefault 20;
        consoleMode = lib.mkDefault "auto";
      };
    };
  };
}
