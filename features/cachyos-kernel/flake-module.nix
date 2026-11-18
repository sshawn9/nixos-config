{
  flake = {
    nixosModules.cachyos-kernel = ./nixos.nix;
    homeModules.cachyos-kernel = ./options.nix;
  };
}
