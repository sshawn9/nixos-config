{
  flake = {
    nixosModules.sops = ./nixos.nix;
    homeModules.sops = ./home-manager.nix;
  };
}
