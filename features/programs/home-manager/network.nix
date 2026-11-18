{ config, lib, ... }:
{
  config = lib.mkIf config.features.programs.enable {
    package.remmina = lib.mkDefault false;
  };
}
