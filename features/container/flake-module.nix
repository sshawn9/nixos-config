{
  flake = {
    nixosModules.container = ./nixos.nix;
    homeModules.container = ./home-manager.nix;
  };
}
