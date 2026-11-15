{ lib, ... }:
{
  package = {
    inshellisense = lib.mkDefault false;
    warp-terminal = lib.mkDefault false;
  };
}
