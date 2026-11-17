{
  flake = {
    nixosModules.system-base = ./nixos.nix;
    homeModules.system-base = ./options.nix;
  };
}
