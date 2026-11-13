{
  lib,
  pkgs,
  ...
}:
{
  services.openssh = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.unstable.openssh;
  };
}
