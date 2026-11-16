{ config, lib, ... }:
{
  config = lib.mkIf config.features.programs.enable {
    package = {
      flameshot = lib.mkDefault false;
      kooha = lib.mkDefault false;
    };
  };
}
