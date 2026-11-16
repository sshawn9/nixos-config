{ lib, ... }:
{
  options.features.mihomo = {
    enable = lib.mkEnableOption "Mihomo proxy integration";
  };
}
