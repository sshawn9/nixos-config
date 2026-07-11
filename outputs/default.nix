{
  self,
  nixpkgs,
  flake-parts,
  ...
}@inputs:
let
  myLib = import (self.outPath + "/lib") { inherit inputs; };
  repoTree = myLib.loadRecursiveModulePathAttrs self.outPath;
  nixpkgsPolicy = import ./nixpkgs.nix { inherit inputs; };

  commonArgs = {
    inherit (nixpkgs) lib;
    inherit
      self
      inputs
      myLib
      repoTree
      nixpkgsPolicy
      ;
  };

  systems = import ./systems.nix commonArgs;
  homes = import ./homes.nix commonArgs;
  configurationChecks = import ./checks.nix {
    inherit (nixpkgs) lib;
    inherit systems homes;
  };
in
flake-parts.lib.mkFlake { inherit inputs; } {
  imports = [
    nixpkgsPolicy.flakeModule
    inputs.treefmt-preset.flakeModules.default
  ];

  systems = configurationChecks.supportedSystems;

  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      checks = configurationChecks.forSystem system;

      treefmt.settings.excludes = [
        ".dotfiles/*/.config/noctalia/**"
        ".dotfiles/*/.config/Code/User/**"
        "sops/secrets/**"
      ];

      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.just
          config.treefmt.build.wrapper
        ];
      };
    };

  flake = {
    inherit (systems) nixosConfigurations darwinConfigurations;
    inherit (homes) homeConfigurations;
  };
}
