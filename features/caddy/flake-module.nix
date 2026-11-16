{
  flake = {
    nixosModules.caddy = ./nixos.nix;
    homeModules.caddy = ./home-manager.nix;
  };
}
