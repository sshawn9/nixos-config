{ self, ... }:
{
  imports = [
    self.nixosModules.system-base
    self.nixosModules.star
    self.nixosModules.ssh
    ./hardware-configuration.nix
    ./system.nix
  ];
}
