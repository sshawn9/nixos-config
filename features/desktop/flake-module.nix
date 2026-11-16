{
  flake = {
    nixosModules.desktop = ./nixos.nix;
    homeModules.desktop = ./home-manager.nix;
  };
}
