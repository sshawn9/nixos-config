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
      (myLib.loadRecursiveModulePathList ./common)
      ++ lib.optionals isLinux (myLib.loadRecursiveModulePathList ./nixos)
      ++ lib.optionals isDarwin (myLib.loadRecursiveModulePathList ./darwin)
      ++ [
        (
          { config, osConfig, ... }:
          lib.mkIf (config.home.username == osConfig.my.shared.username) {
            my.shared = osConfig.my.shared;
          }
        )
      ];
  };
}
