{ lib, ... }:
{
  options.features.git.enable = lib.mkEnableOption "Git tools and configuration";
}
