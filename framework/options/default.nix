{
  flake = {
    nixosModules.commonOptions = ./options.nix;
    systemManagerModules.commonOptions = ./options.nix;
    homeModules.commonOptions = ./options.nix;
  };
}
