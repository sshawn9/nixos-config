{
  flake = {
    nixosModules.programs = ./nixos.nix;
    homeModules.programs = ./home-manager.nix;
  };
}
