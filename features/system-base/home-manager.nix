{ config, lib, ... }:
{
  imports = [
    ./options.nix
    ./nix-caches.nix
  ];

  config = lib.mkIf config.features.system-base.enable {
    xdg = {
      enable = lib.mkDefault true;
      localBinInPath = lib.mkDefault true;
    };
  };
}
