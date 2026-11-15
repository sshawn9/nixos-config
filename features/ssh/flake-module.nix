{
  flake = {
    nixosModules.ssh = ./nixos.nix;
    homeModules.ssh = ./home-manager.nix;
  };
}
