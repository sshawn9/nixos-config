{
  flake = {
    nixosModules.easytier = ./nixos.nix;
    homeModules.easytier = ./home-manager.nix;
  };
}
