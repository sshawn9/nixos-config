inputs:
let
  inherit (inputs.nixpkgs) lib;
  moduleFiles = import ../framework/module-files/discovery.nix { inherit lib; };
  flakeModuleFiles =
    directory:
    if builtins.pathExists directory then
      lib.filter (path: baseNameOf path == "flake-module.nix") (moduleFiles.list directory)
    else
      [ ];
  addModuleKey = module: module // { key = module._file; };
in
inputs.flake-parts.lib.mkFlake { inherit inputs; } {
  imports = [
    inputs.flake-parts.flakeModules.touchup
    inputs.home-manager.flakeModules.home-manager
    ../framework/evaluation-context
    ../framework/file-sources
    ../framework/module-files
    ../framework/nixos-system
    ../framework/options
    ../framework/package
    ../framework/package-sets
    ./features.nix
    ./hosts.nix
    ./homes.nix
    ./installers.nix
    inputs.treefmt-preset.flakeModules.default
  ]
  ++ flakeModuleFiles ../features
  ++ flakeModuleFiles ../compositions/user-presets;

  touchup.attr.nixosModules.any.finish = addModuleKey;
  touchup.attr.homeModules.any.finish = addModuleKey;

  perSystem =
    { config, pkgs, ... }:
    {
      treefmt.settings.excludes = [
        ".dotfiles/*/.config/Code/User/**"
        ".dotfiles/*/.config/DankMaterialShell/**"
        "sops/secrets/**"
        "secrets/**"
        "file-sources/**"
      ];

      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.unstable.just
          config.treefmt.build.wrapper
        ];
      };
    };
}
