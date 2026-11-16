{ lib, ... }:
{
  options.features.container = {
    enable = lib.mkEnableOption "container tools and runtimes";
  };
}
