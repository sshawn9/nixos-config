{
  flake = {
    nixosModules.scheduling = ./nixos.nix;
    homeModules.scheduling = ./options.nix;
  };
}
