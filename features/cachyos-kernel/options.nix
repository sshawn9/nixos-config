{ lib, ... }:
{
  options.features.cachyos-kernel.enable = lib.mkEnableOption "CachyOS kernel";
}
