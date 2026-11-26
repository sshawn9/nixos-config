{
  flake = {
    nixosModules.package = ./nixos.nix;
    systemManagerModules.package = ./system-manager.nix;
    homeModules.package = ./home-manager.nix;
  };
}
