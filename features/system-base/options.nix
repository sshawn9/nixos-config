{ lib, ... }:
{
  options.features.system-base.enable = lib.mkEnableOption "base system configuration";
}
