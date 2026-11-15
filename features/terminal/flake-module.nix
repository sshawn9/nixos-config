{
  flake = {
    nixosModules.terminal = ./nixos.nix;
    homeModules.terminal = ./home-manager.nix;
  };
}
