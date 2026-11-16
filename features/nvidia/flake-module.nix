{
  flake = {
    nixosModules.nvidia = ./nixos.nix;
    homeModules.nvidia = ./home-manager.nix;
  };
}
