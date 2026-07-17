{
  myLib,
  lib,
  system,
  config,
  inputs,
  ...
}@args:
let
  platform = lib.systems.elaborate system;
  inherit (platform) isLinux isDarwin;
in
{
  imports =
    lib.optionals isLinux [
      inputs.home-manager.nixosModules.home-manager
    ]
    ++ lib.optionals isDarwin [
      inputs.home-manager.darwinModules.home-manager
    ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";

    extraSpecialArgs = {
      osConfig = config;
      inherit (args)
        self
        inputs
        system
        myLib
        repoTree
        ;
    };

    sharedModules =
      (myLib.loadRecursiveModulePathList ../../home-manager/common)
      ++ lib.optionals isLinux (myLib.loadRecursiveModulePathList ../../home-manager/nixos)
      ++ lib.optionals isDarwin (myLib.loadRecursiveModulePathList ../../home-manager/darwin)
      ++ [
        ./compat.nix
        (
          { config, osConfig, ... }:
          lib.mkIf (config.home.username == osConfig.my.shared.username) {
            my.shared = osConfig.my.shared;
          }
        )
      ];
  };
}
