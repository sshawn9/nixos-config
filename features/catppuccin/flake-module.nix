{
  flake = {
    nixosModules.catppuccin = ./options.nix;
    homeModules.catppuccin = ./home-manager.nix;
  };
}
