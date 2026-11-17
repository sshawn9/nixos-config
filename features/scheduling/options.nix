{ lib, ... }:
{
  options.features.scheduling.enable = lib.mkEnableOption "sched_ext CPU scheduling";
}
