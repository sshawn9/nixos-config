{ self, ... }:
{
  imports = [
    self.nixosModules.star
    self.nixosModules.ssh
    ./hardware-configuration.nix
    ./system.nix
  ];
}
