{ lib, ... }:
{
  options.features.programs-cli.enable = lib.mkEnableOption "command-line programs and tools";
}
