{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.nvidia.enable {
    package.nvtop.package = lib.mkDefault pkgs.unstable.nvtopPackages.full;
  };
}
