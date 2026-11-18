{
  flake = {
    nixosModules.system-tuning = ./nixos.nix;
    homeModules.system-tuning = ./options.nix;
  };
}
