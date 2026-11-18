{
  flake = {
    nixosModules.system-base = ./nixos.nix;
    homeModules.system-base = ./home-manager.nix;
  };
}
