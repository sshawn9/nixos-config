{
  lib,
  pkgs,
  ...
}:
{
  services.avahi = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.unstable.avahi;
    nssmdns4 = lib.mkDefault true;
    publish = {
      enable = lib.mkDefault true;
      userServices = lib.mkDefault true;
    };
  };
}
