{ lib, ... }:
{
  options.features.nvidia.enable = lib.mkEnableOption "NVIDIA GPU support";
}
