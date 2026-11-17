{
  flake = {
    nixosModules.mihomo = ./nixos.nix;
    homeModules.mihomo = ./options.nix;
  };
}
