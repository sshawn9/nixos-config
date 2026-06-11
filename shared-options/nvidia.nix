{ lib, system, ... }:

lib.optionalAttrs (lib.hasSuffix "linux" system) {
  options.my.shared.nvidia.enable = lib.mkEnableOption "NVIDIA";
}
