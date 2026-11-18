{
  config,
  lib,
  pkgs,
  ...
}:
let
  service = config.services.mihomo;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.mihomo.enable {
    services.mihomo = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.mihomo;
      tunMode = lib.mkDefault true;
      configFile = lib.mkDefault "/etc/mihomo/config.yaml";
      webui = lib.mkDefault pkgs.unstable.zashboard;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf service.enable [ 7890 ];
  };
}
