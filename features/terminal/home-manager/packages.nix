{ config, lib, ... }:
{
  config = lib.mkIf config.features.terminal.enable {
    package = {
      inshellisense = lib.mkDefault false;
      warp-terminal = lib.mkDefault false;
    };
  };
}
