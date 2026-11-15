{
  config,
  inputs,
  ...
}:
let
  inherit (config.flake.lib) evaluationContext;
  nixosPackage = config.flake.nixosModules.package;
  homePackage = config.flake.homeModules.package;
  fileSources = config.flake.homeModules.fileSources;

  homeManager =
    args@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      context = evaluationContext args;
    in
    {
      key = "${toString ./default.nix}#homeManager";
      imports =
        lib.optionals context.isNixOS [
          inputs.home-manager.nixosModules.home-manager
          nixosPackage
        ]
        ++ lib.optionals context.isHomeManager [
          homePackage
          fileSources
          ./home.nix
        ];

      config = lib.mkMerge [
        (lib.optionalAttrs context.isNixOS {
          home-manager = {
            useGlobalPkgs = lib.mkDefault true;
            useUserPackages = lib.mkDefault true;
            backupFileExtension = lib.mkDefault "hm-backup";
            extraSpecialArgs = {
              inherit inputs;
              inherit (inputs) self;
              system = pkgs.stdenv.hostPlatform.system;
            };
            sharedModules = [ homeManager ];
          };
        })
        (lib.optionalAttrs context.isStandaloneHome {
          home.homeDirectory = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
            lib.mkDefault (if config.home.username == "root" then "/root" else "/home/${config.home.username}")
          );
          programs.home-manager.enable = lib.mkDefault true;
          nix.package = lib.mkDefault pkgs.nix;
        })
      ];
    };
in
{
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    inputs.home-manager.flakeModules.home-manager
    ../evaluation-context/default.nix
    ../file-sources/default.nix
    ../package/default.nix
  ];

  flake = {
    flakeModules.homeManager = ./default.nix;
    modules.generic.homeManager = homeManager;
    modules.generic.framework.imports = [ config.flake.modules.generic.homeManager ];
  };
}
