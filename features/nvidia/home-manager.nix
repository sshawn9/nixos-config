{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.features.nvidia.enable {
    package.nvtop = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.unstable.nvtopPackages.full;
    };
  };
}
