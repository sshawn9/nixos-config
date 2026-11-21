{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.features.easytier.enable && config.features.easytier.client.enable) {
    assertions = [
      {
        assertion = config.features.easytier.client.configServer != null;
        message = "features.easytier.client.configServer must be set when the client is enabled.";
      }
    ];

    services.easytier = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.easytier;
      instances.client.configServer = lib.mkDefault config.features.easytier.client.configServer;
    };
  };
}
