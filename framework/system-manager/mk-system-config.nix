{ inputs, withSystem }:
{ system, modules }:
withSystem system (
  { pkgs, ... }:
  let
    inherit (inputs) self;
    inherit (inputs.nixpkgs) lib;
  in
  inputs.system-manager.lib.makeSystemConfig {
    # Upstream evalModules has no class; identify this backend for HM's osClass.
    specialArgs = {
      inherit inputs self;
      _class = "systemManager";
    };
    # Share package-set settings; System Manager creates its own pkgs.
    inherit (pkgs) overlays;
    modules = [
      self.systemManagerModules.commonOptions
      self.systemManagerModules.package
      self.systemManagerModules.fileSources
      self.systemManagerModules.allFeatures
      inputs.home-manager.nixosModules.home-manager
      ./shared-options.nix
      {
        nixpkgs.hostPlatform = system;
        nixpkgs.config = lib.mkDefault pkgs.config;
        home-manager = {
          useGlobalPkgs = lib.mkDefault true;
          useUserPackages = lib.mkDefault true;
          extraSpecialArgs = { inherit inputs self; };
          sharedModules = [
            self.homeModules.commonOptions
            self.homeModules.package
            self.homeModules.fileSources
            self.homeModules.allFeatures
            (
              { pkgs, ... }:
              {
                nix.package = lib.mkDefault pkgs.unstable.nix;
              }
            )
          ];
        };
      }
    ]
    ++ modules;
  }
)
