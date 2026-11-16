{
  flake = {
    nixosModules.commonOptions = ./options.nix;
    homeModules.commonOptions = ./options.nix;
  };
}
