{
  config,
  lib,
  pkgs,
  ...
}:

let
  sopsEnabled = config.my.shared.sops.enable;
in
{
  services.easytier = {
    enable = lib.mkDefault false;
    package = lib.mkDefault pkgs.stable.easytier;
    instances = {
      default = {
        configServer = "\${ET_CONFIG_SERVER}";
        environmentFiles = lib.mkIf sopsEnabled [
          config.sops.secrets.easytier_config_server.path
        ];
      };
    };
  };

  sops.secrets.easytier_config_server = lib.mkIf sopsEnabled {
    restartUnits = [ "easytier-default.service" ];
  };

  assertions = [
    {
      assertion =
        config.services.easytier.enable
        -> config.services.easytier.instances.default.environmentFiles != [ ];
      message = ''
        services.easytier resolves configServer from ET_CONFIG_SERVER, which normally
        comes from sops. Either enable my.shared.sops or supply
        services.easytier.instances.default.environmentFiles yourself.
      '';
    }
  ];

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
