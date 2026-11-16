{ lib, ... }:
{
  options.features.programs.enable = lib.mkEnableOption "application programs and tools";
}
