{
  flake = {
    nixosModules.star = ./nixos.nix;
    homeModules.star = ./home-manager.nix;
  };
}
