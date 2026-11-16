{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.features.libvirt.enable {
    services.cockpit = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.unstable.cockpit;
      port = lib.mkDefault 9091;
      plugins = [ pkgs.unstable.cockpit-machines ];
      openFirewall = lib.mkDefault true;
    };
  };
}
