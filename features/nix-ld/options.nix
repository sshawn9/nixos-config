{ lib, ... }:
{
  options.features.nix-ld.enable = lib.mkEnableOption "nix-ld and its runtime libraries";
}
