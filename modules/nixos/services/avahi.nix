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
    settings.publish = {
      disable-publishing = lib.mkDefault false;
      disable-user-service-publishing = lib.mkDefault false;
      publish-addresses = lib.mkDefault true;
    };
  };
}
