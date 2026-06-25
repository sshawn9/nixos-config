{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.easytier = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.stable.easytier;
    instances = {
      default = {
        configServer = "\${ET_CONFIG_SERVER}";
        environmentFiles = [
          config.sops.secrets.easytier_config_server.path
        ];
      };
    };
  };

  systemd.services.easytier-default = {
    unitConfig = {
      StartLimitIntervalSec = 0;
    };
    serviceConfig = {
      RestartSec = 5;
      RestartSteps = 10;
      RestartMaxDelaySec = 300;
    };
  };
}
