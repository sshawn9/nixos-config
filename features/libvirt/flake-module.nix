{
  flake = {
    nixosModules.libvirt = ./nixos.nix;
    homeModules.libvirt = ./home-manager.nix;
  };
}
