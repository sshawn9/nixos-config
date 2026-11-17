{
  flake = {
    nixosModules.nix-ld = ./nixos.nix;
    homeModules.nix-ld = ./options.nix;
  };
}
