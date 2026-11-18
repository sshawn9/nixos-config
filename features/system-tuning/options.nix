{ lib, ... }:
{
  options.features.system-tuning.enable = lib.mkEnableOption "system tuning";
}
