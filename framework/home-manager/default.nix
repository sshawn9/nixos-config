{ inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  flake = {
    nixosModules.homeManager = ./nixos.nix;
    homeModules.homeManager = ./home-manager.nix;
  };
}
