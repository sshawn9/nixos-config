{
  flake = {
    nixosModules.package = ./nixos.nix;
    homeModules.package = ./home-manager.nix;
  };
}
