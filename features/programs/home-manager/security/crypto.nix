{ config, lib, ... }:
{
  config = lib.mkIf config.features.programs.enable {
    package = {
      age = lib.mkDefault true;
      openssl = lib.mkDefault true;
      ssh-to-age = lib.mkDefault true;
      sops = lib.mkDefault true;
    };
  };
}
