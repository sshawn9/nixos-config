{ lib, ... }:
{
  options.features.scheduling.enable = lib.mkEnableOption "CPU and process scheduling";
}
