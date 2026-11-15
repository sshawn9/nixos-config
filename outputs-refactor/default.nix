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
in
inputs.flake-parts.lib.mkFlake { inherit inputs; } {
  imports = [
    ../framework/file-sources
    ../framework/home-manager
    ../framework/module-files
    ../framework/package
    ../framework/package-sets
    ./hosts.nix
    ./homes.nix
    inputs.treefmt-preset.flakeModules.default
  ]
  ++ flakeModuleFiles ../features
  ++ flakeModuleFiles ../compositions/user-presets;

  perSystem =
    { config, pkgs, ... }:
    {
      treefmt.settings.excludes = [
        ".dotfiles/*/.config/Code/User/**"
        ".dotfiles/*/.config/DankMaterialShell/**"
        "sops/secrets/**"
      ];

      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.unstable.just
          config.treefmt.build.wrapper
        ];
      };
    };
}
