{ inputs, withSystem }:
{ system, modules }:
withSystem system (
  { pkgs, ... }:
  let
    inherit (inputs) self;
    inherit (inputs.nixpkgs) lib;
  in
  lib.nixosSystem {
    specialArgs = { inherit inputs self; };
    modules = [
      self.nixosModules.commonOptions
      self.nixosModules.package
      self.nixosModules.fileSources
      self.nixosModules.allFeatures
      inputs.home-manager.nixosModules.home-manager
      ./shared-options.nix
      {
        nixpkgs.pkgs = pkgs;
        home-manager = {
          useGlobalPkgs = lib.mkDefault true;
          useUserPackages = lib.mkDefault true;
          extraSpecialArgs = { inherit inputs self; };
          sharedModules = [
            self.homeModules.commonOptions
            self.homeModules.package
            self.homeModules.fileSources
            self.homeModules.allFeatures
          ];
        };
      }
    ]
    ++ modules;
  }
)
