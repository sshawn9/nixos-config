{ self, lib, ... }:
{
  imports = [ self.homeModules.star ];
  fileSources.localRoot = "/etc/nixos/config";

  features = {
    desktop = {
      enable = lib.mkDefault true;
      niri.enable = lib.mkDefault true;
      noctalia.enable = lib.mkDefault true;
    };
    sops.enable = false;
  };
}
